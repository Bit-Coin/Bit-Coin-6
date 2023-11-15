source 'https://rubygems.org'
source 'https://rails-assets.org'

ruby '2.1.4'

gem 'rails', '4.2.2'
gem 'dotenv-rails', groups: [ :development, :test ]  # load this before anything else

# Data
gem 'acts-as-taggable-array-on'
gem 'attr_encrypted'
gem 'aws-sdk'
gem 'descriptive_statistics', '~> 2.4.0', :require => 'descriptive_statistics/safe'
gem 'faker'
gem 'pg'
gem 'phony_rails'

# Assets
gem 'coffee-rails', '~> 4.1.0'
gem 'nokogiri', '>= 1.11.4'
gem 'sass-rails', '~> 5.0.0'
gem 'slim'
gem 'therubyracer',  platforms: :ruby
gem 'uglifier', '>= 1.3.0'

# Auth
gem 'devise', '>= 3.5.1'
gem 'simple_token_authentication', '~> 1.10', '>= 1.10.0'

# Front-end
gem 'autoprefixer-rails'
gem 'bootstrap_form'
gem 'draper', '>= 3.0.0'
gem 'font-awesome-rails', '>= 4.4.0.0'
gem 'jbuilder'
gem 'modernizr-rails'
gem 'useragent'

# Back-end
gem 'aasm'
gem 'business_time'
gem 'kaminari', '>= 0.17.0'
gem 'paperclip', require: 'paperclip'
gem 'rails_admin', '>= 0.6.8'
gem 'resque'
gem 'resque_mailer', '>= 2.3.0'
gem 'resque-scheduler'
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
  gem 'minitest-rails-capybara', '~> 2.1.2'
  gem 'minitest-reporters'
  gem 'poltergeist', '~> 1.7.0'
  gem 'resque_unit'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'mailcatcher'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', '~> 0.46.0', require: false
  gem 'bullet'
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
  gem 'unicorn-rails'
end
gem 'ckeditor_rails', '>= 4.5.11'
