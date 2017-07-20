# Refresh demo

heroku maintenance:on -a ripple-demo
heroku ps:scale web=0 worker=0 scheduler=0 -a ripple-demo
# git push demo demo:master
bash db/script/copy_prod_to_demo.sh
heroku run rails runner db/script/one_time/migrate_stubs.rb -a ripple-demo
heroku run rails runner db/script/one_time/run_after_20150529201906.rb -a ripple-demo
heroku run rails runner db/script/one_time/set_up_fannie_mae.rb -a ripple-demo
heroku run rails runner db/script/one_time/set_up_limeade.rb -a ripple-demo
heroku run rails runner 'db/script/one_time/gutcheck.rb' -a ripple-demo
heroku ps:scale web=1 worker=1 scheduler=1 -a ripple-demo
heroku maintenance:off -a ripple-demo
