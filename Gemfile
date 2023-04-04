source 'https://rubygems.org'
source 'https://rails-assets.org'

ruby '2.1.4'

gem 'rails', '6.1.7.3'
gem 'dotenv-rails', groups: [ :development, :test ]  # load this before anything else

# Data
gem 'acts-as-taggable-array-on', '>= 0.4.0'
gem 'attr_encrypted'
gem 'aws-sdk'
gem 'descriptive_statistics', '~> 2.4.0', :require => 'descriptive_statistics/safe'
gem 'faker'
gem 'pg'
gem 'phony_rails'

# Assets
gem 'coffee-rails', '~> 4.2.2'
gem 'nokogiri', '>= 1.13.9'
gem 'sass-rails', '~> 6.0.0'
gem 'slim'
gem 'therubyracer',  platforms: :ruby
gem 'uglifier', '>= 2.7.2'

# Auth
gem 'devise', '>= 4.7.1'
gem 'simple_token_authentication', '~> 1.16', '>= 1.16.0'

# Front-end
gem 'autoprefixer-rails'
gem 'bootstrap_form'
gem 'draper'
gem 'font-awesome-rails', '>= 4.7.0.6'
gem 'jbuilder', '>= 2.6.4'
gem 'modernizr-rails'
gem 'useragent'

# Back-end
gem 'aasm'
gem 'business_time'
gem 'kaminari', '>= 1.2.1'
gem 'paperclip', '>= 5.2.1', require: 'paperclip'
gem 'rails_admin', '>= 2.0.0'
gem 'resque'
gem 'resque_mailer'
gem 'resque-scheduler'
gem 'stripe', '>= 1.36.1'
gem 'impressionist'

# Services
gem 'sendgrid-ruby' # sending
gem 'sendgrid_toolkit', '>= 1.4.0' # api functions (bounces, etc.)
gem 'twilio-ruby', '~> 3.12'
gem "select2-rails"
gem 'readmorejs-rails'

group :test do
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'minitest'
  gem 'minitest-rails-capybara', '~> 3.0.0'
  gem 'minitest-reporters'
  gem 'poltergeist', '~> 1.6.0'
  gem 'resque_unit'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'mailcatcher', '>= 0.6.5'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', '~> 0.49.0', require: false
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
gem 'ckeditor_rails'
