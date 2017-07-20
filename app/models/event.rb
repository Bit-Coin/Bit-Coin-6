class Event < ActiveRecord::Base

  belongs_to :user
  belongs_to :company
  belongs_to :eventable, polymorphic: true

  # To override default values for ActivityLogger
  attr_reader :text, :icon_emoji, :channel, :body

  before_create :set_defaults, :set_user_and_company
  after_create :notify

  # Severities

  rails_admin do
    include_fields :id, :eventable_id, :eventable_type, :note
    list do
      field :id
      field :created_at
      field :updated_at
      field :eventable_id
      field :eventable_type
    end
  end
  INFO = 'info'
  WARN = 'warn'
  NOTIFY = 'notify'
  CRITICAL = 'critical'
  SEVERITIES = [INFO, WARN, NOTIFY, CRITICAL]

  validate :known_severity
  validates_presence_of :name # disallow empty string
  validates_presence_of :type # STI

  # HACK WORKAROUND for https://www.pivotaltracker.com/story/show/95414560
  def body
    self['body']
  end

  # Override this method in descendant classes if you want
  # something custom
  def alert_preamble
    text = user ? user.email : ''
    text += " [#{company.name}]" if company
    text
  end

  private

  def known_severity
    unless SEVERITIES.include?(severity)
      errors.add(:severity, "must be one of #{SEVERITIES}")
    end
  end

  def notify
    text = (body && body['message']) ? body['message'] : "#{alert_preamble} #{type} #{id} #{name}"
    channel = get_channel
    if channel
      Ripple::ActivityLogger.new({
        channel: channel,
        text: text,
        icon_emoji: get_emoji
      }).log!
    end
  end

  def get_channel
    return channel if channel.present?
    case severity
    when INFO
      if (user && user.settings[:debug]) ||
            (company && company.settings[:debug]) ||
            ENV['ACTIVITY_DEBUG'] == 'true' # debug everything w/ ENV
        channel = '#activity'
      else
        return false # skip notification
      end
    when WARN
      channel = '#activity'
    when CRITICAL
      channel = '#alert'
    when NOTIFY
      channel = '#activity'
    else
      raise "Unknown severity #{severity}"
    end
    channel
  end

  def get_emoji
    icon_emoji || (base_event && base_event[:icon_emoji]) || ':ghost:'
  end

  def set_defaults
    self.severity ||= severity || base_event[:severity] || INFO
    self.body ||= body || (base_event && base_event[:body]) || {}
  end

  def set_user_and_company
    raise "Descendant classes must implement"
  end

  def base_event
    "#{type}::EVENTS".constantize[name.to_sym]
  end
end
