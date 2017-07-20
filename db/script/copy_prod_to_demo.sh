# copy production database to demo

# depends on heroku-toolbelt being installed locally

# RUN THIS FROM YOUR DEV ENV
# $ bash db/script/copy_prod_to_demo.sh

# turn maintenance on demo
heroku maintenance:on -a ripple-demo
heroku ps:scale web=0 worker=0 scheduler=0 -a ripple-demo

# current state of prod db, expires oldest backup
# heroku pg:backups capture -a ripple-production

# drop & recreate demo
heroku pg:reset DATABASE -a ripple-demo

# copy data
heroku pg:backups restore `heroku pg:backups public-url -a ripple-production` DATABASE -a ripple-demo

heroku run rake db:migrate -a ripple-demo

# turn maintenance back off 
heroku ps:scale web=1 worker=1 scheduler=1 -a ripple-demo
heroku maintenance:off -a ripple-demo

# for good measure (sometimes it seems to lose the DB connection when toggling maintenance)
heroku restart -a ripple-demo
