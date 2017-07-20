# Cheat Sheets
# http://www.mattsears.com/articles/2011/12/10/minitest-quick-reference
# https://gist.github.com/zhengjia/428105 <-- Capybara
# https://github.com/blowmage/minitest-rails-capybara

# phantomjs bin downloads: https://bitbucket.org/ariya/phantomjs/downloads

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails/capybara'
require 'capybara/poltergeist'
require 'capybara-screenshot/minitest'
require 'webmock/minitest'
require 'database_cleaner'
require "minitest/reporters"
Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each {|file| require file }

require_relative './fixtures/acme_demo'
require_relative './fixtures/ripple'

# You are not allowed to talk to the internets during tests
WebMock.disable_net_connect!(:allow_localhost => true) 

# Reporter
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new(:color => true)

# For JS testing
Capybara.javascript_driver = :poltergeist
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run

class TestHelper
  class << self
    def seed_db
      # Loads all characteristics, roles, questions, survey sets and plans
      YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'characteristics.yml')).each do |params|
        Characteristic.create! params
      end
      YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'roles.yml')).each do |params|
        Role.create! params 
      end
      YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'plans.yml')).each do |params|
        Plan.create! params
      end
      YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'response_sets.yml')).each do |params|
        ResponseSet.create! params 
      end
      YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'survey_series.yml')).each do |params|
        SurveySeries.create! params 
      end
      Ripple::SurveyQuestionsImporter.import!('db/seeds/ripple50.csv')
      Ripple::SurveyQuestionsImporter.import!('db/seeds/project_questions.csv')

      # reset pks after these yml loads b/c some pk values are specified
      ActiveRecord::Base.connection.tables.each { |t| ActiveRecord::Base.connection.reset_pk_sequence!(t) }
    end

    def seed_custom_questions
      Ripple::SurveyQuestionsImporter.import!('db/seeds/lll_questions.csv')
    end
    
    def seed_admin
      Admin.create!(
        email: 'demo+admin@ripplecrew.com',
        password: Security::DEMO_PASSWORD,
        first_name: 'Thor',
        last_name: 'Thegodofthunder'
      )
    end

    def seed_prospect
      prospect = User.create!({
        first_name: 'Ogdred',
        last_name: 'Weary',
        email: Faker::Internet.email,
        password: Security::DEMO_PASSWORD,
        pending_company_name: Faker::Company.name,
        type: 'prospect',
        state: 'active'
      })
      prospect.confirm!
      prospect
    end
    
    def test_javascript
      Capybara.current_driver = Capybara.javascript_driver
    end

    def stop_testing_javascript
      Capybara.use_default_driver # :rack_test
    end
  end
end


class ActiveSupport::TestCase
  def setup
    super
    ActionMailer::Base.deliveries.clear
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  def teardown
    super
    Resque.reset!
    Timecop.return
    DatabaseCleaner.clean
  end
end

class ActionController::TestCase
  include Devise::TestHelpers

  def setup
    super
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    super
    Ripple::CompanyContext.clear
    cookies.clear
    DatabaseCleaner.clean
  end
end

class Capybara::Rails::TestCase
  include Warden::Test::Helpers
  Warden.test_mode!

  def setup
    super
    DatabaseCleaner.clean
  end

  def teardown
    super
    TestHelper.stop_testing_javascript
    Warden.test_reset!
    Ripple::CompanyContext.clear
  end
  
  def set_host(host)
    default_url_options[:host] = host
    Capybara.app_host = "http://" + host
  end
end

# Start the tests with a clean database containing only the seeds
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean
TestHelper.seed_db

# And who knows what's going on with this?
# Not working.  possible conflict w/ resque-scheduler
Resque.inline = true 
