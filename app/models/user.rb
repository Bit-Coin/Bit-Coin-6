class User < ActiveRecord::Base
  self.inheritance_column = :_type_disabled # so we can have a column named 'type'
  acts_as_token_authenticatable
  acts_as_taggable_array_on :tags
  before_destroy :destroy_related_surveys

  include Messageable
  include Eventable

  ############ Associations ########################
  belongs_to :company
  belongs_to :team
  has_many :invitations, foreign_key: 'receiver_id'
  has_many :user_roles, dependent: :destroy
  # Plans for which user is receiver is in #survey_plans, aliased as #receiver_survey_plans
  has_many :giver_survey_plans, dependent: :destroy, class_name: 'SurveyPlan', foreign_key: 'giver_id'
  has_many :short_paths, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :personal_scores, -> (score) { where("cohort_name is null") }, {class_name: 'Score', foreign_key: 'receiver_id'}
  has_many :self_scores, -> (score) { where("cohort_name = 'self'") }, {class_name: 'Score', foreign_key: 'receiver_id'}
  has_many :surveys, dependent: :destroy, foreign_key: 'giver_id' # users are not allowed to see received survey results
  has_many :comments, dependent: :destroy, foreign_key: 'receiver_id'
  has_many :team_members, dependent: :destroy
  has_many :teams, :through => :team_members
  has_many :manage_teams, -> { where(team_members: { is_manager: true}) }, :through => :team_members




  has_many :feedback, class_name: 'Survey', foreign_key: 'receiver_id' do
    def score_current_feedback!
      # The effect of this is all in how you call it. If you call
      #   user.feedback.score_current_feedback! => all scores including self-survey
      #   user.others_feedback.score_current_feedback! => scores from other people only
      #   user.self_feedback.score_current_feedback! => self-survey scores only
      transaction do
        surveys = self.scorable.current.includes(:responses => {:characteristic => {}})
        survey_scorer = Ripple::UserSurveyScorer.new(proxy_association.owner, surveys)
        survey_scorer.create_scores
        survey_scorer.mark_scored
      end
    end
  end

  ############# Configurations ###########################
  include Configurable
  inherit_settings_from 'team_or_company'

  ############### Hstore Accessors #######################
  # TODO drop hstore and move options to Configurable
  store_accessor :options, :use_sms, :pending_company_name

  # We pass the company name from the controller so we
  # can create new companies in this here model, but
  # that attr is not on User directly, so we...
  attr_accessor :company_name

  ############### Devise Stuff #################
  # WARNING Custom mailers in CustomDeviseMailer.  Do not turn on
  # lockable without implementing a mailer method.
  devise :database_authenticatable, :recoverable, :rememberable,
          :trackable, :registerable, :confirmable
  include PasswordComplexable
  include Devise::Models::RippleValidatable

  def self.find_for_database_authentication(conditions)
    find_for_authentication(conditions.merge(:company_id => Ripple::CompanyContext.company.id))
  end

  ############ Validations #####################
  phony_normalize :mobile_phone, :default_country_code => 'US'
  validates_plausible_phone :mobile_phone
  validates_confirmation_of :email
  validate :company_or_placeholder_name, :known_state, :known_type

  ############ Callbacks #######################
  after_save :set_default_user_role
  after_commit :set_short_path, unless: Proc.new { |record| record.short_paths.active }
  after_save :create_self_surveys, if: :promoted_to_rippler?

  ################### States, Types, and Scopes #############
  # Types
  # 'prospect' is not a member of a beta company
  # 'unregistered_giver' has been invited by a rippler, but hasn't registered
  # 'rippler' is fully registered (aka 'active')

  RIPPLER = 'rippler'
  PROSPECT = 'prospect'
  UNREGISTERED_GIVER = 'unregistered_giver'
  TYPES = [RIPPLER, PROSPECT, UNREGISTERED_GIVER]

  # States
  # 'active' means they've confirmed their email or completed a survey
  # 'invited' is for unregistered_givers who haven't responded yet.  Their email
  #           could be bad.
  # 'unsubscribed' means "I don't want to get any more survey requests for anyone"
  # 'deleted' by admin
  # 'unresponsive' means they haven't clicked anything in a month
  # 'bouncing' means bad email

  ACTIVE = 'active'
  INVITED = 'invited'
  STATES = %w(active invited bouncing unsubscribed deleted unresponsive)

  scope :prospect, -> { where('type = ?', PROSPECT) }
  scope :unregistered_givers, -> { where('type = ?', UNREGISTERED_GIVER) }
  scope :rippler, -> { where('type = ?', RIPPLER) }
  scope :not_rippler, -> { where('type != ?', RIPPLER) }
  scope :ripplers, -> { rippler } # gets me all the time
  scope :only_registered, -> { where('type != ?', UNREGISTERED_GIVER) }
  scope :active, -> { where('state = ?', 'active') }
  scope :invited, -> { where('state = ?', 'invited') }

  scope :bouncing, -> { where('state = ?', 'bouncing') }
  scope :unsubscribed, -> { where('state = ?', 'unsubscribed') }
  scope :deleted, -> { where('state = ?', 'deleted') }
  scope :unresponsive, -> { where('state = ?', 'unresponsive') }
  scope :executives, -> { joins(user_roles: :role).where('roles.name = ?', "executive") }
  scope :ugs_and_ripplers, -> { where('users.type in (?)', %w(rippler unregistered_giver)) }
  scope :invitable, -> { where('state not in (?)', %w(bouncing unsubscribed deleted)) }
  scope :remindable, -> { where('state not in (?)', %w(bouncing unsubscribed deleted unresponsive)) }
  scope :in_cohort, lambda { |cohort| where(:cohort => cohort) }
  scope :pilot, -> { joins(:company).where('teams.type = ?', 'pilot') }

  class << self
    # Monkey-patch Devise to choose highest-id User record by default
    def find_first_by_auth_conditions(tainted_conditions, opts={})
      to_adapter.find_first(
        order: [:id, :desc],
        conditions: devise_parameter_filter.filter(tainted_conditions).merge(opts)
      )
    end

    # Continuing the above monkey-patch (or else it uses find_first in Devise...)
    def send_reset_password_instructions(attributes={})
      recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
      recoverable.send_reset_password_instructions if recoverable.persisted?
      recoverable
    end

    def need_reminding(time=Time.now)
      # TODO kill me!
      company_ids = Company.has_config(:reminder_hour, time.hour).pluck(:id)
      users_with_company_setting = User.where('company_id in (?)', company_ids).pluck(:id)
      users_with_positive_overrides =
        User.has_custom_config(:reminder_hour, time.hour).pluck(:id)
      users_with_negative_overrides =
        User.has_not_custom_config(:reminder_hour, time.hour).pluck(:id)
      users_recently_reminded = User.recently_reminded.pluck(:id)

      ids = users_with_company_setting +
              users_with_positive_overrides -
              users_with_negative_overrides
      ids = ids.uniq - users_recently_reminded
      ugs_and_ripplers.remindable.where('id in (?)', ids).where('id in (?)', Survey.open.pluck(:giver_id).uniq)
      # TODO also remind users who have new scores but haven't logged in
    end

    def recently_reminded(at=Time.now)
      if [4, 5].include? at.wday # Thurs, Fri
        days = 3
      elsif [1, 2, 3].include? at.wday # Mon - Wed
        days = 2
      else # Sat, Sun
        return User.all # do not remind anyone on the weekend
      end
      User.where("date_trunc('hour', last_reminded_at) > ?", days.business_days.before(at))
    end

    def last_reminded_on(date=Date.today)
      where('last_reminded_at::date = ?', date)
    end

    def find_by_short_path(path)
      # NB: This method will find users with expired paths too
      user = ShortPath.where('short_paths.path = ?', path).first.try(:user)
      Ripple::CompanyContext.company = user.company if user
      user
    end
  end # class methods

  # current_user is the root of the scope chain
  # here are the other scopes...
  include Scopes::Scores
  include Scopes::Surveys
  include Scopes::Colleagues

  ######### end scopes & class methods

  ########### Instance Methods #######################

  # TODO Is there a more elegant way to get the grandchildren?
  def survey_plans # all for which self is receiver, including self-survey
    SurveyPlan.where('user_role_id in (?)', user_roles.pluck(:id))
  end

  def can_create_survey?
    feedback_type.nil? || feedback_type.include?('receiver')
  end

  def survey_plans_excluding_self
    survey_plans.where('giver_id != ?', id)
  end
  alias_method :receiver_survey_plans, :survey_plans_excluding_self

  def recently_reminded?(at=Time.now)
    User.recently_reminded(at).pluck(:id).include?(self.id)
  end

  # Prevents prospects from logging in
  def active_for_authentication?
    rippler? || unregistered_giver?
  end

  def others_feedback
    # the semantics of this are actually "surveys completed by others about me"
    self.feedback.for_others
  end

  def self_feedback
    # the semantics of this are actually "surveys completed by me about me"
    self.feedback.for_self
  end

  def sent_invitations # synonym
    invitations
  end

  def received_invitations
    Invitation.where('giver_id = ?', id)
  end

  def full_name
    if first_name && last_name
      first_name + ' ' + last_name
    else
      email
    end
  end

  def first_name_or_your
    if first_name && (first_name != '')
      first_name + "'s"
    else
      "Your"
    end
  end

  def company_placeholder_name
    if company
      company.name
    elsif pending_company_name
      pending_company_name
    else
      'Undefined'
    end
  end

  def relationship_type_options
    settings[:relationship_types].split(',').map(&:strip).unshift(nil)
  end

  def crew
    User.where('id in (?)', invitations.active_or_notified.pluck(:giver_id))
  end

  def crew_ids
    self.invitations.active_or_notified.pluck(:giver_id).uniq
  end

  def short_path
    short_paths.active.try(:path) || set_short_path.path
  end

  def valid_short_path?(path)
    short_paths.order(created_at: :desc).limit(2).pluck(:path).include?(path)
  end

  def redeliver_surveys
    Ripple::Reminder.new([self]).remind!
  end

  def default_user_role
    user_roles.order(:id).first # points to 'colleague' role in default case
  end

  def bounce!
    ActiveRecord::Base.transaction do
      self.state = 'bouncing'
      save
      giver_survey_plans.update_all(state: 'bounced')
      Survey.open.where('giver_id = ?', id).update_all(state: 'void')

      message = "#{email} bounced [#{company.try(:name)}]."
      logger = Ripple::ActivityLogger.new(text: message, icon_emoji: ':basketball:',
        channel: '#activity')
      logger.log!
    end
  end

  def unsubscribe!
    ActiveRecord::Base.transaction do
      self.state = 'unsubscribed'
      self.unsubscribed_at = Time.now
      save
      giver_survey_plans.update_all(state: 'unsubscribed')
      Survey.open.where('giver_id = ?', id).update_all(state: 'void')

      message = "#{email} has unsubscribed [#{company.try(:name)}]."
      logger = Ripple::ActivityLogger.new(text: message, icon_emoji: ':poop:',
        channel: '#activity')
      logger.log!
    end
  end

  def destroy_related_surveys
    surveys = Survey.where('receiver_id = ? OR giver_id = ?', self.id, self.id)
    surveys.delete_all if surveys.present?
  end

  def delete!
    # Things to do when a user is deleted:
    # - void all open surveys where that user is giver or receiver
    # - delete all invitations where that user is giver or receiver
    # - void open self-surveys
    # - set that user's state to :deleted
    # - set that user's password to a secure random value

    result = true
    channel = '#activity'

    Survey.where('giver_id = ?', id).open.update_all(state: 'void')
    Survey.where('receiver_id = ?', id).open.update_all(state: 'void')

    giver_survey_plans.update_all(state: 'deleted')
    receiver_survey_plans.update_all(state: 'deleted')

    unless survey_plans.active.any? || surveys.open.any?
      newpass = User.new(password: SecureRandom.password).encrypted_password
      update_attributes(state: 'deleted', encrypted_password: newpass)
      message = "User ID #{id}: #{full_name} (#{email}) [#{company_placeholder_name}] has been deleted"
    else
      message = "There was an error trying to delete user ID #{id} (#{email})"
      channel = '#activity'
      result = false
    end

    Ripple::ActivityLogger.new(text: message, channel: channel, icon_emoji: ':no_pedestrians:').log!
    result
  end

  def mark_unresponsive!
    ActiveRecord::Base.transaction do
      self.state = 'unresponsive'
      save!
      giver_survey_plans.notified.update_all(state: 'timed_out')
      surveys.open.update_all(state: 'void')
    end

    message = "User ID #{id} #{full_name} (#{email}) has been marked unresponsive"
    Ripple::ActivityLogger.new(text: message, icon_emoji: ':sleeping:').log!
  end

  def well_look_whos_here!
    update_attributes(state: 'active') unless deleted?
  end
  alias_method :mark_active!, :well_look_whos_here!

  # Sets survey_plan.state = 'timed_out' in cases
  # where self is not unresponsive, just wants to
  # ignore a certain person or people.
  def cull_expired_invitations!
    giver_survey_plans.notified.each do |sp|
      if sp.timed_out?
        ActiveRecord::Base.transaction do
          sp.surveys.open.update_all(state: 'void')
          sp.update_attributes(state: 'timed_out')
        end
      end
    end
  end

  def active?
    state == ACTIVE
  end

  def invited?
    state == 'invited'
  end

  def unsubscribed?
    state == 'unsubscribed'
  end

  def bouncing?
    state == 'bouncing'
  end

  def deleted?
    state == 'deleted'
  end

  def unresponsive?
    state == 'unresponsive'
  end

  def rippler?
    type == RIPPLER
  end

  def prospect? # not part of beta company
    type == PROSPECT
  end

  def unregistered_giver?
    type == UNREGISTERED_GIVER
  end

  # If user has any invitations to fake friends, s/he's
  # a test-driver.
  def test_driver?
    c = Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)
    return false unless company == c
    uids = invitations.pluck(:giver_id)
    emails = User.where('id in (?)', uids).pluck(:email)
    (emails & Ripple::Globals::TESTDRIVE_AUTO_FRIENDS).any? &&
      !Ripple::Globals::TESTDRIVE_AUTO_FRIENDS.include?(self.email)
  end

  def do_not_contact?
    unsubscribed? || bouncing? || deleted?
  end

  def sufficiently_registered?
    first_name && last_name
  end

  # Ripplers, by definition, cannot be marked unresponsive
  def appears_unresponsive?
    type == 'unregistered_giver' &&
    surveys.closed.count == 0 &&
      created_at < (Time.now - company.settings[:weeks_until_invitations_expire].weeks)
  end

  def promoted_to_rippler?
    type == 'rippler' && type_was != 'rippler'
  end

  def use_sms?
    use_sms == '1' && mobile_phone
  end

  ########## Self-survey stuff
  def self_surveys_due?
    return false unless rippler? && active?
    survey_plans.for_self.due.any?
  end

  # TODO get rid of #create_self_surveys
  def create_self_surveys
    raise "Cannot create self surveys for inactive or non-rippler users" \
      unless rippler? && active? # don't create self surveys for non ripplers
    survey_plans.for_self.due.each do |sp|
      sp.create_next_survey
    end
  end

  def self_surveys
    surveys.for_self.open
  end
  ######### end self-survey stuff

  # The first login by the first user at a new company
  def prompt_for_company_domain?
    company.domain.blank? && sign_in_count == 1 && !webmail_domain?
  end

  def email_domain
    email.split('@')[1]
  end

  def webmail_domain?
    Ripple::FreeEmailProviders.domains.include? email_domain
  end

  # Support for being proxied by an admin account

  belongs_to :proxy, :class_name => 'Admin'

  def has_proxy?
    proxy.present?
  end

  def generate_proxy_secret
    SecureRandom.base64(30)
  end

  def set_proxy!(admin)
    Ripple::CompanyContext.company = self.company
    self.proxy = admin
    self.proxy_secret = generate_proxy_secret
    self.save!
  end

  def discard_proxy!
    Ripple::CompanyContext.clear
    self.proxy = nil
    self.proxy_secret = nil
    self.save!
  end

  # end proxy stuff

  def set_short_path
    existing_user = User.find_by_id(self.id)
    self.short_paths.create! if existing_user.present?
  end

  def confirmation_required?
    # Overwrite confirmable callback so unregistered givers
    # don't get confirmation emails
    !confirmed? && !unregistered_giver?
  end

  def subscription_owner?
    company.subscriptions.active && company.subscriptions.active.owner_id === self.id
  end

  def host
    if company
      company.host
    elsif Rails.env.production?
      "www.ripplecrew.com"
    elsif Rails.env.staging?
      "staging.ripplecrew.com"
    elsif Rails.env.demo?
      "demo.ripplecrew.com"
    else
      "dev.ripplecrew.com"
    end
  end

  def is_team_leader?
    # self.team.present? && self.team.manager == self
    self.manage_teams.present?
  end
  
  def is_executive?
    user_roles.map{|ur| ur.role.name}.include? "executive"
  end

  def can_manage_team?(team)
    TeamMember.where(:team_id => team.id, :user_id => self.id, :is_manager => true).present?
  end

  def is_self_survey?
    survey_plans.map(&:giver_id).include?(id)
  end

  def add_role(role)
    role_id = Role.find_by(name: role).id
    user_roles.create!({role_id: role_id, surveyable: self.company})
  end

  private

  def set_default_user_role
    if rippler? && user_roles.blank?
      user_roles.create!({role_id: 1, surveyable: self.company})
    end
  end

  # Temporary solution until we figure out how to handle
  # all manner of random self-registrations
  def company_or_placeholder_name
    if %w(rippler unregistered_giver).include?(type) && company.blank?
      errors.add :company, "cannot be blank for ripplers or unregistered_givers"
    elsif type == 'prospect' && pending_company_name.blank?
      errors.add :pending_company_name, "must be present for prospects"
    end
  end

  def known_state
    unless STATES.include? state
      errors.add :state, "unknown: #{state}"
    end
  end

  def known_type
    unless TYPES.include? type
      errors.add :type, "unknown: #{type}"
    end
  end

  def team_or_company # called by inherit_from
    return team || company
  end
end
