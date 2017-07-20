GUARDED_TASKS = [
  'db:drop',
  'db:migrate:reset',
  'db:schema:load',
  'db:seed',
  'db:reset'
]

# set env var SKIP_DB_GUARD=true to skip interactive prompt

namespace :db do
  desc "Require confirmation of destructive action"
  task :guard do
    if ['development', 'staging', 'production'].include? Rails.env
      unless ENV['SKIP_DB_GUARD'] == 'true'
        print 'Destructive action. Type name of Rails.env to continue: '
        unless $stdin.gets.chomp == Rails.env
          exit
        end
      end
    end
  end
end

GUARDED_TASKS.each do |task|
  Rake::Task[task].enhance ['db:guard']
end
