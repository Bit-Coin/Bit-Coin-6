class Company < ActiveRecord::Base

  self.inheritance_column = :_type_disabled # so we can have a column named 'type'

  attr_encrypted :ripple_api_key, key: ENV['ATTR_ENCRYPTED_KEY']
  attr_encrypted :ripple_api_token, key: ENV['ATTR_ENCRYPTED_KEY']

  include Surveyable

  # TRICKY Company.scores returns ALL scores in the company scope
  # Company.scores_for_company returns the scores at the company level

  belongs_to :manager, class_name: 'User'
    has_many :scores, dependent: :destroy
    has_many :events, dependent: :destroy
    has_many :teams, dependent: :destroy
    has_many :users, dependent: :destroy
    has_many :projects, dependent: :destroy
    has_many :company_survey_series, dependent: :destroy
    has_many :user_roles, as: :surveyable

  has_many :feedback, :through => :users do
    def score_current_feedback!
      transaction do
        surveys = self.scorable.for_others.current.includes(:responses => {:characteristic => {}})
        survey_scorer = Ripple::CompanySurveyScorer.new(proxy_association.owner, surveys)
        survey_scorer.create_scores
        survey_scorer.mark_scored
        true
      end
    end
  end

  has_many :subscriptions do
    include TimeSpannable

    def active
      self.active_state.active_time.first
    end

    def ordered
      self.order('start_at, end_at')
    end
  end

  has_many :subscription_events, :through => :subscriptions
  has_many :invoices

  ##################### CONFIGURATIONS #################################
  include Configurable
  # Company is top-level, so no 'inherit_from'

  # DEPRECATED Remove after 20150529201906 migration and scripts are run
  set_default_config :project_feedback, :boolean, false,
    "Allow project- and role-based feedback", scope: :protected
  set_default_config :hyperspeed, :boolean, false,
    "Assign next survey in two hours (hyperspeed)"
  set_default_config :accelerated_surveys, :boolean, false,
    "Allow completion of one survey per invitation per day (accelerated mode)"
  set_default_config :weeks_with_weekly_surveys, :integer, 52,
    "Number of weeks before the survey frequency flips from weekly to monthly"
  set_default_config :allow_comments, :boolean, false,
    "Allow optional text comments on surveys"
  set_default_config :months_between_self_surveys, :integer, 12,
    "Months between self-surveys", scope: :protected

  # PRIVATE (default):  cannot be overridden, except at the Company level
  set_default_config :spoof_receiver_email, :boolean, true,
    "Use surveyee's email address as reply-to for initial invitation"
  set_default_config :weeks_until_invitations_expire, :integer,
    Ripple::Globals::MAX_DAYS_TO_RESPOND / 7,
    "Weeks until unanswered invitations expire"
  set_default_config :cohorts, :string,
    "Associate,Manager,Director,Vice President,Senior VP,Executive VP,C-Level",
    "Valid cohort values"

  set_default_config :consultant_mode, :boolean, false,
    "Disable invitations and unregistered_giver account promotion (consultant mode)"

    set_default_config :access_development_tools, :boolean, true,
    "Disable development tools for company users"

  # PROTECTED:  can be overridden at the Company or Team levels
  set_default_config :relationship_types, :string,
    "Colleague,Peer,Manager,Direct Report,Report",
    "Valid relationship types", scope: :protected
  set_default_config :relationship_tags, :string,
    "N/A", "Valid relationship tags", scope: :protected # placeholder

  # PUBLIC:  can be overridden by Company, Team, or User
  set_default_config :reminder_hour, :integer,
    Ripple::Time.default_reminder_hour,
    "Hour of day in Eastern time during which to send reminders (0-23)",
    scope: :public
  set_default_config :show_bad_password, :boolean, false,
    "Log cleartext submitted password on login failure",
    scope: :public
  set_default_config :show_dashboard, :string, "true", scope: :public
  ################### END CONFIG #################################

  TYPES = %w(demo test pilot client deleted)
  validate :of_known_type
  scope :demo, -> { where('type = ?', 'demo') }
  scope :test, -> { where('type = ?', 'test') }
  scope :pilot, -> { where('type = ?', 'pilot') }
  scope :accelerated, -> { has_config(:accelerated_surveys, true) }
  scope :client, -> { where('type = ?', 'client') }
  scope :deleted, -> { where('type = ?', 'deleted') }

  validates :name, presence: true, uniqueness: true
  validates :domain, uniqueness: true, if: 'domain.present?'
  validates :stub, presence: true, uniqueness: true
  validates :manager_id, presence: true, if: Proc.new { |c| c.members.any? }

  def parent_characteristics
    ssids = company_survey_series.active.pluck(:survey_series_id).uniq
    cids = SurveySeries.where('id in (?)', ssids).pluck(:parent_characteristic_id).uniq
    Characteristic.where('id in (?)', cids).order(:id)
  end

  # Is there a better way to fetch grandchildren?
  def survey_plans
    SurveyPlan.where('company_survey_series_id in (?)',
      company_survey_series.pluck(:id))
  end

  def use_series(ssid, config={})
    ss = SurveySeries.find(ssid)
    company_survey_series.create!({
      survey_series_id: ssid,
      config: ss.default_config.merge(config)
    })
  end

  def accelerated?
    settings[:accelerated_surveys]
  end

  # legacy
  def all_members
    users
  end

  def hyperspeed?
    settings[:hyperspeed]
  end

  alias_method :members, :all_members
  alias_method :employees, :all_members

  def maven
    manager
  end

  def default_company_survey_series
    company_survey_series.ripple50_others
  end
  alias_method :default_css, :default_company_survey_series

  def cohort_options
    settings[:cohorts].split(',').map(&:strip).unshift(nil)
  end

  def relationship_tags
    settings[:relationship_tags].split(',').map(&:strip)
  end

  def scores_for_company
    scores.where('receiver_id is null').where(:cohort_name => 'company').where('team_id is null')
  end

  def main_scores_for_company
    scores_for_company.where('question_id is null')
  end

  def invitations
    members = users.pluck(:id)
    Invitation.where('giver_id in (?) or receiver_id in (?)', members, members)
  end

  def surveys
    members = users.pluck(:id)
    Survey.where('giver_id in (?) or receiver_id in (?)', members, members)
  end

  def host
    if Rails.env.production?
      "#{stub}.ripplecrew.com"
    elsif Rails.env.staging?
      "#{stub}.staging.ripplecrew.com"
    elsif Rails.env.demo?
      "#{stub}.demo.ripplecrew.com"
    else
      "#{stub}.dev.ripplecrew.com"
    end
  end

  # Destroy all company, user, self, question, and characteristic
  # scores for this company and its users for all competency
  # models
  def destroy_all_scores
    scores.destroy_all # company scores
    Score.where('receiver_id in (?)', users.pluck(:id)).destroy_all # self and others
    # question/characteristic scores are in the above
  end

  private

  def of_known_type
    unless TYPES.include?(type)
      errors.add "Unknown company type: #{type}"
    end
  end
end
