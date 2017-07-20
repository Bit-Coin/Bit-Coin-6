namespace :db do

  desc 'Reset all user passwords to demo password'
  task :reset_passwords => :environment do
    puts 'Changing all user passwords to Security::DEMO_PASSWORD.'
    User.update_all(encrypted_password: Security::ENCRYPTED_DEMO_PASSWORD)
  end
  
  desc 'Seed the database with fake company data'
  task :fake => :environment do
    Resque.inline = true
    require_relative '../../test/fixtures/acme_demo'
    AcmeHelper.generate_acme_company_data
    Resque.inline = false
  end
  
end
