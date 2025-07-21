source 'https://rubygems.org'
source 'https://rails-assets.org'

ruby '2.1.4'

gem 'rails', '7.1.0'
gem 'dotenv-rails', groups: [ :development, :test ]  # load this before anything else

# Data
gem 'acts-as-taggable-array-on', '>= 0.4.0'
gem 'attr_encrypted'
gem 'aws-sdk'
gem 'descriptive_statistics', '~> 2.4.0', :require => 'descriptive_statistics/safe'
gem 'faker'
gem 'pg'
gem 'phony_rails', '>= 0.12.7'

# Assets
gem 'coffee-rails', '~> 4.2.2'
gem 'nokogiri'
gem 'sass-rails', '~> 4.0.3'
gem 'slim'
gem 'therubyracer',  platforms: :ruby
gem 'uglifier', '>= 1.3.0'

# Auth
gem 'devise', '>= 4.7.0'
gem 'simple_token_authentication', '~> 1.18', '>= 1.18.0'

# Front-end
gem 'autoprefixer-rails'
gem 'bootstrap_form'
gem 'draper', '>= 3.1.0'
gem 'font-awesome-rails', '>= 4.7.0.8'
gem 'jbuilder', '>= 2.6.4'
gem 'modernizr-rails'
gem 'useragent'

# Back-end
gem 'aasm'
gem 'business_time', '>= 0.7.5'
gem 'kaminari', '>= 0.17.0'
gem 'paperclip', '>= 4.2.2', require: 'paperclip'
gem 'rails_admin', '>= 3.0.0'
gem 'resque', '>= 1.26.0'
gem 'resque_mailer', '>= 2.3.0'
gem 'resque-scheduler', '>= 4.4.0'
gem 'stripe'
gem 'impressionist', '>= 1.6.0'

# Services
gem 'sendgrid-ruby' # sending
gem 'sendgrid_toolkit', '>= 1.1.1' # api functions (bounces, etc.)
gem 'twilio-ruby', '~> 3.12'
gem "select2-rails"
gem 'readmorejs-rails'

group :test do
  gem 'capybara-screenshot', '>= 1.0.10'
  gem 'database_cleaner'
  gem 'minitest'
  gem 'minitest-rails-capybara', '~> 3.0.0'
  gem 'minitest-reporters'
  gem 'poltergeist', '~> 1.7.0'
  gem 'resque_unit'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'mailcatcher', '>= 0.10.0'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', '~> 0.46.0', require: false
  gem 'bullet', '>= 5.5.0'
end

group :production, :staging do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
end

group :production do
  gem 'honeybadger', '~> 2.0'
  gem 'newrelic_rpm'
end

group :staging, :test, :production do
  gem 'unicorn'
  gem 'unicorn-rails', '>= 2.2.1'
end
gem 'ckeditor_rails', '>= 4.5.11'
