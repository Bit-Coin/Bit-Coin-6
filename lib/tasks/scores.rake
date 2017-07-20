namespace :scores do
  desc 'Recalculate scores for all users'
  task :recalc => :environment do
  	Job::UpdateScores.perform(:force => true)
  end

  desc 'Run Job::UpdateScores but do not force full recalc'
  task :update => :environment do
  	Job::UpdateScores.perform
  end
end