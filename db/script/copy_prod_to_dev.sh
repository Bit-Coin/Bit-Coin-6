# copy prod to dev

# NOTE: bad idea infosec-wise.  Get rid of this
# when infosec becomes a priority.

# TODO kill resque & rails server.  Must do those manually for now
bundle exec rake db:drop
heroku pg:pull DATABASE ripple_development -a ripple-production
bundle exec rake db:migrate

# reset test db
echo 'Resetting test database'
bundle exec rake db:reset RAILS_ENV=test

# TODO restart resque & server

# If you don't want to or can't use pg:pull
#   curl -o tmp/db.dump `heroku pgbackups:url -a ripple-production`
#   rake db:drop db:create
#   pg_restore --verbose --clean --no-acl --no-owner -h localhost -U ripple -d ripple_development tmp/db.dump
#   rake db:migrate
