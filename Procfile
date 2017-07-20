web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
resque: env TERM_CHILD=1 COUNT=4 bundle exec rake resque:workers
scheduler: bundle exec rake resque:scheduler
