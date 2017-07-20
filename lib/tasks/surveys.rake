namespace :surveys do
  desc 'Run Job::CreateSurveys normally'
  task :heartbeat => :environment do
    Job::CreateSurveys.perform
  end

  desc 'Run Job::CreateSurveys ignoring the day/time'
  task :makeitso => :environment do
    Job::CreateSurveys.perform([], :force => true)
  end

  desc "fix survey records"
  task :fix_survey => :environment do
    Survey.for_others.each do |s|
      puts "checking for #{s.id} survey"
      unless s.receiver.present? && s.giver.present?
        s.delete
        puts " Survey #{s.id} is deleted because either receiver or giver not present."
      end
    end
  end
end
