# Production release script

heroku maintenance:on -a ripple-production
heroku ps:scale web=0 worker=0 scheduler=0 -a ripple-production
heroku pg:backups capture -a ripple-production
wget `heroku pg:backups public-url -a ripple-production` -O tmp/latest_prod.dump
git push production master
heroku run rake db:migrate -a ripple-production
heroku run rails runner db/script/one_time/migrate_stubs.rb -a ripple-production
heroku run rails runner db/script/one_time/run_after_20150529201906.rb -a ripple-production
heroku run rails runner db/script/one_time/set_up_fannie_mae.rb -a ripple-production
heroku run rails runner 'db/script/one_time/gutcheck.rb' -a ripple-production
heroku ps:scale web=2 worker=2 scheduler=1 -a ripple-production
heroku maintenance:off -a ripple-production
