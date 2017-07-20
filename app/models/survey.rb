class Survey < ActiveRecord::Base

  belongs_to :giver, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :survey_plan
  belongs_to :survey_set
  belongs_to :parent_characteristic, class_name: 'Characteristic'
  has_many :comments

  has_many :responses do
    def set_random_scores
      self.update_all('score = ' + Response::RANDOM_SCORE_SQL)
    end
  end

  include Messageable
  include Eventable

  ########### STATES
  # pending:  DEPRECATED
  # open:     ready for feedback
  # complete: answered but not scored
  # scored:   added to results
  # void:     declined
  STATES = %w( open complete scored void )

  before_create :set_defaults
  after_create :void_duplicates

  validates :giver, presence: true
  validates :receiver, presence: true
  validate :completed_at_not_null
  validate :known_state
  validates_presence_of :survey_plan_id, :survey_set_id, :parent_characteristic_id

  scope :closed, -> { where('surveys.state not in (?)', %w(pending open void)) }
  scope :open, -> { where('surveys.state = ?', 'open') }
  scope :complete, -> { where('surveys.state = ?', 'complete') }
  scope :scored, -> { where('surveys.state = ?', 'scored') }
  scope :pending, -> { where('surveys.state = ?', 'pending') } # DEPRECATED
  scope :scorable, -> { where('surveys.state in (?)', %w(complete scored)) }
  scope :complete_or_scored, -> { scorable } # semantic candy (good MIT band name)
  scope :void, -> { where('surveys.state = ?', 'void') }
  scope :not_void, -> { where('surveys.state != ?', 'void') }
  scope :current, -> { where('surveys.completed_at >= ?', Time.now - Ripple::Globals::SURVEY_AGE_LIMIT.days) }
  scope :oldest, -> { order(created_at: :asc).first }
  scope :newest, -> { order(created_at: :desc).first }
  scope :this_week, -> { where('created_at >= ?', Ripple::Time.new().beginning_of_week) }
  scope :for_self, -> { where('giver_id = receiver_id') }
  scope :for_others, -> { where('giver_id != receiver_id') }

  class << self
    def for_pair(giver, receiver)
      where('surveys.giver_id = ?', giver.id).where('surveys.receiver_id = ?', receiver.id)
    end

    # TODO These seem tortured.  Is there a simpler way?
    def for_team(team_id)
      joins(:receiver).where('users.team_id = ?', team_id)
    end

    def for_cohort(cohort_name)
      joins(:receiver).where('users.cohort = ?', cohort_name)
    end

    def unique_receiver_ids
      pluck(:receiver_id).uniq
    end

    def unique_receivers
      User.where('id in (?)', unique_receiver_ids)
    end

    def unique_team_ids
      unique_receivers.pluck(:team_id).uniq
    end

    def unique_cohort_names
      unique_receivers.pluck(:cohort).uniq
    end

    def collection_company_id
      ids = unique_receivers.pluck(:company_id).uniq
      raise 'Multi-company scoring not implemented' unless ids.size == 1
      ids[0]
    end
  end # class << self

  def config
    survey_plan.company_survey_series.config
  end

  def due_date
    created_at + 3.days
  end

  def self_survey?
    giver === receiver
  end

  def new?
    survey_plan.created?
  end

  def past_due?
    due_date < Time.now
  end

  def pending?
    state == 'pending'
  end

  def open?
    state == 'open'
  end

  def assign_questions! # legacy support
    survey_plan.assign_questions(self)
  end

  def decline!
    ActiveRecord::Base.transaction do
      survey_plan.update_attributes(state: 'declined')
      update_attributes(state: 'void')
    end

    message = "#{self.giver.email} declined an invitation from #{self.receiver.email}"
    logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':thumbsdown:')
    logger.log!
  end

  def complete!
    if complete_enough?
      if self.state != 'complete' # hack to avoid firing two messages on final survey
        if self.self_survey?
          message = "#{self.giver.full_name} completed a self-survey for #{self.receiver.company.name}"
        elsif self.comments.final.any?
          message = "#{self.receiver.company.name}'s survey is completed by #{self.giver.full_name} for #{self.receiver.full_name} with comments"
        else
          message = "#{self.receiver.company.name}'s survey is completed by #{self.giver.full_name} for #{self.receiver.full_name}"
        end
        logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':thumbsup:')
        logger.log!
      end

      ActiveRecord::Base.transaction do
        self.state = 'complete'
        self.completed_at = Time.now
        save!
        survey_plan.survey_completed
        true
      end
    else
      false
    end
  end

  private

  def self.set_params(options)
    params = { published_at: Time.now, state: 'published' } # common
    params[:company_id] = collection_company_id # must have a company
    params[:receiver_id] ||= options[:receiver_id]
    params[:team_id] ||= options[:team_id]
    params[:cohort_name] ||= options[:cohort_name]
    params
  end

  def set_defaults
    self.state ||= 'open'
  end

  def void_duplicates
    duplicates = self.giver.surveys.open
                      .where('receiver_id = ?', self.receiver_id)
                      .where('created_at < ?', self.created_at)
                      .where('survey_plan_id = ?', self.survey_plan_id)
    duplicates.update_all(state: 'void') if duplicates.any?
  end

  def complete_enough?
    responses.where('responses.score is null').count == 0
  end

  def completed_at_not_null
    state == 'completed' ? completed_at : true
  end

  def known_state
    STATES.include? state
  end
end
