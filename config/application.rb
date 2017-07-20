require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ripple
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')

    config.action_mailer.delivery_method = :smtp

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end

# Logging defaults
Resque.logger = Logger.new(STDOUT)
Resque.logger.level = Logger::ERROR
$stdout.sync = true

ActionMailer::Base.smtp_settings = {
  :user_name => ENV['SENDGRID_USERNAME'],
  :password => ENV['SENDGRID_PASSWORD'],
  :domain => 'ripplecrew.com',
  :address => 'smtp.sendgrid.net',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}

module Ripple
  class Globals
    # Constants and magic numbers that we want to use throughout the application
    # and are NOT configurable by Company, User, etc.

    # Configurable contextual constants should be set in the models like
    # include Configurable
    # set_default_config(:name, :type, 'default value', "Help text to explain it")

    # MIN_SURVEYS_FOR_SCORES - The minimum number of completed surveys a user
    # must have before that user will see any scores on their dashboard
    MIN_SURVEYS_FOR_SCORES = 5 

    # SURVEY_AGE_LIMIT - The maxmimum number of days old a survey can be and
    # still count toward the receiver's scores
    SURVEY_AGE_LIMIT = 365

    # Short paths expire in 2X this value.  Invitations time out
    # after 1X this value.
    MAX_DAYS_TO_RESPOND = 28

    # Browser blacklist (anything below this gets a warning)
    Browser = Struct.new(:browser, :version)
    UnsupportedBrowsers = [
      Browser.new("Internet Explorer", "10.0")
    ]

    # Name of the default company to use for "test drives"
    TESTDRIVE_COMPANY_NAME = "Ripple Analytics Inc."

    # Email addresses of test drive company users to auto-survey for new drivers
    TESTDRIVE_AUTO_FRIENDS = [ "bob@ripplecrew.com",
                               "noah@ripplecrew.com", 
                               "matt@ripplecrew.com",  
                               "tom@ripplecrew.com",
                               "support@ripplecrew.com" ]
  end
end
