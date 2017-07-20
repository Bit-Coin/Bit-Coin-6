# restore dev db from local pgdump

if [ -z "$1" ]
then
  echo "Usage: bash $0 path/to/sql.dump"
  exit 1
fi

SKIP_DB_GUARD=true bundle exec rake db:drop
createdb -U ripple -O ripple ripple_development
createdb -U ripple -O ripple ripple_test
pg_restore --verbose --clean --no-acl --no-owner -d ripple_development $1
bundle exec rake db:migrate
rails runner "ActiveRecord::Base.connection.tables.each { |t| ActiveRecord::Base.connection.reset_pk_sequence!(t) }"
exit 0
