#!/bin/bash

# THIS IS FOR DEV PURPOSES ONLY.  DO NOT RUN IN PRODUCTION!

bash db/script/restore_dev_from_dump.sh tmp/latest.dump
rails runner db/script/one_time/migrate_stubs.rb
rails runner db/script/one_time/run_after_20150529201906.rb
rails runner db/script/one_time/set_up_fannie_mae.rb
rails runner db/script/one_time/set_up_limeade.rb
bundle exec rake test TEST='db/script/one_time/whole_schmear_test.rb'
rails runner 'db/script/one_time/gutcheck.rb'

# bundle exec rake test:unit 
# bundle exec rake test:features

echo "Enough change for you?"

# To update demo
# ==========================================================
# bash db/script/copy_prod_to_demo.sh
# heroku run rails runner db/script/one_time/migrate_stubs.rb -a ripple-demo
# heroku run rails runner db/script/one_time/run_after_20150529201906.rb -a ripple-demo
# heroku run rails runner db/script/one_time/set_up_fannie_mae.rb -a ripple-demo
# heroku run rails runner 'db/script/one_time/gutcheck.rb' -a ripple-demo
