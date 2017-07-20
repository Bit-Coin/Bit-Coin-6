class SurveyPlan < ActiveRecord::Base
  acts_as_taggable_array_on :relationship_tags

  belongs_to :user_role
  has_one :receiver, through: :user_role, source: :user
  belongs_to :giver, class_name: 'User'
  belongs_to :company_survey_series
  has_many :surveys

  include Eventable

  validates_presence_of :next_due
  validate :uniqueness, on: :create
  validate :not_for_self, on: :create, if: Proc.new { |sp| sp.company_survey_series.for_others? }
  validate :for_self, on: :create, if: Proc.new { |sp| sp.company_survey_series.for_self? }

  before_create :set_defaults

  ############# STATES
  # created:      giver not yet notified (DEFAULT)
  # notified:     giver not yet responded
  # active:       giver has responded to at least one survey for receiver
  # declined:     giver clicked "I don't know receiver"
  # bounced:      giver email bounced
  # unsubscribed: giver clicked 'unsubscribe' in email footer
  # deleted:      giver is also a taker
  # timed_out:    no response after X weeks (company setting)
  STATES = %w(created notified active bounced declined unsubscribed deleted timed_out)
  scope :created, -> { where('state = ?', 'created') }
  scope :notified, -> { where('state = ?', 'notified') }
  scope :active, -> { where('state = ?', 'active') }
  scope :active_or_notified, -> { where('state in (?)', %w(active notified)) }
  scope :created_or_notified, -> { where('state in (?)', %w(created notified)) }
  scope :not_dead, -> { where('state in (?)', %w(created notified active)) }

  scope :not_active, -> { where('state != ?', 'active') } 
  scope :bounced, -> { where('state = ?', 'bounced') }
  scope :declined, -> { where('state = ?', 'declined') }
  scope :unsubscribed, -> { where('state = ?', 'unsubscribed') }
  scope :deleted, -> { where('state = ?', 'deleted') }
  scope :undeleted, -> { where('state != ?', 'deleted') }
  scope :timed_out, -> { where('state = ?', 'timed_out') }
  scope :due, -> { active.where('next_due <= ?', Time.now) }
  #####################

  class << self
    def for_self
      css_ids = CompanySurveySeries.for_self.pluck(:id)
      where('company_survey_series_id in (?)', css_ids)
    end

    def for_others
      css_ids = CompanySurveySeries.for_others.pluck(:id)
      where('company_survey_series_id in (?)', css_ids)
    end

    def for_pair(giver, receiver, company_survey_series=nil)
      gs = for_giver(giver, company_survey_series)
      gs.any? ? gs.for_receiver(receiver, company_survey_series) : self.none
    end

    def for_giver(user, company_survey_series=nil)
      scope = where(giver: user)
      if company_survey_series
        scope = scope.where(company_survey_series: company_survey_series)
      end
      scope
    end

    def for_receiver(user, company_survey_series=nil)
      ur_ids = UserRole.where('user_id = ?', user.id).pluck(:id)
      scope = where('user_role_id in (?)', ur_ids)
      if company_survey_series
        scope = scope.where(company_survey_series: company_survey_series)
      end
      scope
    end

    # Convenience method for API plan creation
    # params = {receiver: User, giver: User or nil, email: string, state: 'whatever'}
    def build_from_params(params)
      giver = params[:giver] || 
        params[:receiver].company.members.create!({
          email: params[:email], 
          password: SecureRandom.password, 
          type: 'unregistered_giver',
          state: 'invited', 
          company: params[:receiver].company
        })
      # TODO handle creating plans for different roles
      user_role = params[:receiver].default_user_role
      css = params[:css] || user_role.guess_company_survey_series(giver)
      new({
        user_role: user_role,
        company_survey_series: css,
        giver: giver, 
        state: params[:state] || 'created',
        next_due: Time.now, 
        last_reminded_at: Time.now
      })
    end

    def sorted_for_view
      joins("
          JOIN (VALUES
            ('created',       0),
            ('bounced',       1),
            ('unsubscribed',  2),
            ('timed_out',     3),
            ('declined',      4),
            ('notified',      5),
            ('active',        6))
          AS state_idx(order_state, ordering) 
          ON survey_plans.state = state_idx.order_state
        ").order('state_idx.ordering').order(created_at: :desc)
    end
  end # class methods

  def newest_survey
    surveys.order(:created_at).last
  end

  def due?
    next_due <= Time.now
  end

  def open_survey?
    newest_survey.open?
  end

  def for_self?
    giver === receiver
  end
  alias_method :self_survey?, :for_self?

  def for_other?
    !for_self?
  end

  def age_in_weeks
    (Time.now - last_reminded_at).to_i / (7*24*60*60)
  end

  def activate!
    update_attributes(state: 'active')
  end

  def active_since
    surveys.closed.oldest.try(:completed_at)
  end

  def new_plan?
    state == 'created' && surveys.open.count == 1 && surveys.count == 1
  end

  def created?
    state == 'created'
  end

  def active?
    state == 'active'
  end

  def pending?
    state == 'pending'
  end

  def notified?
    state == 'notified'
  end

  def timed_out?
    state == 'timed_out' || age_in_weeks >= giver.company.settings[:weeks_until_invitations_expire]
  end

  # Called by Survey#complete! in a transaction
  def survey_completed
    update_attributes({state: 'active'})
    # next_due and next_survey_set are set when the Survey is created, not completed
  end

  def create_next_survey
    ActiveRecord::Base.transaction do
      survey = create_survey
      if survey
        assign_questions(survey)
        update_attributes(next_due: set_next_due, next_survey_set_id: next_id_for_pair)
        survey
      end
    end
  end
  alias_method :generate_next_survey, :create_next_survey # bit me multiple times

  def create_survey
    unless giver.feedback_type.try(:include?, 'giver')
      surveys.create!({
        giver: giver,
        receiver: receiver,
        state: 'open',
        survey_set_id: next_survey_set_id,
        parent_characteristic_id: company_survey_series.survey_series.parent_characteristic_id
      }) if company_survey_series.present?
    end
  end

  def assign_questions(survey)
    idx = next_index_for_pair
    active_sets_for_series[idx].questions.each do |question|
      survey.responses.create!({
        :question => question,
        :characteristic => question.characteristic
      })
    end
    true
  end

  def delete!
    ActiveRecord::Base.transaction do
      surveys.open.update_all(state: 'void')
      # TODO What to do w/ Messages and Events?
      update_attributes(state: 'deleted')
    end
    true
  end

  def undelete!
    update_attributes(state: 'active')
  end

  # Used to notify giver of a new invitation. Must be called by the 
  # method creating the survey.
  def notify!
    if new_plan?
      ActiveRecord::Base.transaction do
        SurveysMailer.new_invitation(surveys.open.last.id).deliver
        update_attributes({state: 'notified', last_reminded_at: Time.now})
        log_event!('new_plan', {severity: 'notify'})
      end
    else
      raise "This does not seem to be a new plan"
    end
  end

  def resend!
    # SurveysMailer will not send if invitation.state == 'active'
    survey = surveys.open.last
    if survey
      ActiveRecord::Base.transaction do
        SurveysMailer.new_invitation(survey.id).deliver
        update_attributes(last_reminded_at: Time.now)
      end
      true
    else
      false
    end
  end

  private

  def start_index_for_pair
    receiver.id % active_sets_for_series.length
  end

  def next_index_for_pair
    (start_index_for_pair + count_surveys_for_pair) % active_sets_for_series.length
  end

  def next_id_for_pair
    active_sets_for_series[next_index_for_pair].id
  end

  def count_surveys_for_pair
    surveys.not_void.count
  end

  def active_sets_for_series
    company_survey_series.survey_series.survey_sets.active.ordered_by_position.to_a
  end

  def set_next_due
    if company_survey_series.config['create_manually']
      Ripple::Time::WHEN_ROBOTS_RULE
    elsif newest_survey.present?
      newest_survey.created_at + 
        company_survey_series.config['hours_between_surveys'].hours
    else
      Time.now
    end
  end

  def set_defaults
    self.state ||= 'created'
    self.last_reminded_at ||= nil
    self.next_due ||= Time.now
    self.next_survey_set_id ||= next_id_for_pair
  end

  def uniqueness
    if self.class.where({
        giver: giver,
        user_role: user_role,
        company_survey_series: company_survey_series,
        state: state
      }).any?
      errors.add :giver_id, "is not unique for this user role, survey series, and state"
    end
  end

  def not_for_self
    if giver === receiver
      errors.add :giver_id, "cannot give for this survey plan"
    end
  end

  def for_self
    unless giver === receiver
      errors.add :giver_id, "cannot give for this survey plan"
    end
  end
end
