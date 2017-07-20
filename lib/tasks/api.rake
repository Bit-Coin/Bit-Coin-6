namespace :api do
  desc 'Bomb the api'
  task :ddos => :environment do
    id = Company.first.id
    10000.times do
      Resque.enqueue(Job::PostEmail, id, RippleApi::TestEmail)
    end
  end
end
