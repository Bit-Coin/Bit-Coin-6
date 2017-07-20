# Refresh staging

heroku maintenance:on -a ripple-staging
heroku ps:scale web=0 worker=0 scheduler=0 -a ripple-staging
git push staging staging:master
bash db/script/copy_prod_to_staging.sh
heroku run rails runner db/script/one_time/migrate_stubs.rb -a ripple-staging
heroku run rails runner db/script/one_time/run_after_20150529201906.rb -a ripple-staging
heroku run rails runner db/script/one_time/set_up_fannie_mae.rb -a ripple-staging
heroku run rails runner 'db/script/one_time/gutcheck.rb' -a ripple-staging
heroku ps:scale web=1 worker=1 scheduler=1 -a ripple-staging
heroku maintenance:off -a ripple-staging
