# copy production database to staging

# depends on heroku-toolbelt being installed locally

# RUN THIS FROM YOUR DEV ENV
# $ bash db/script/copy_prod_to_staging.sh

# turn maintenance on staging
heroku maintenance:on -a ripple-staging
heroku ps:scale web=0 worker=0 scheduler=0 -a ripple-staging

# current state of prod db, expires oldest backup
heroku pg:backups capture -a ripple-production

# drop & recreate staging
heroku pg:reset DATABASE -a ripple-staging

# copy data
heroku pg:backups restore `heroku pg:backups public-url -a ripple-production` DATABASE -a ripple-staging

# run rake db:migrate since the code on staging is probably newer than the code on prod
heroku run rake db:migrate -a ripple-staging

# turn maintenance back off 
heroku ps:scale web=1 worker=1 scheduler=1 -a ripple-staging
heroku maintenance:off -a ripple-staging

# for good measure (sometimes it seems to lose the DB connection when toggling maintenance)
heroku restart -a ripple-staging

# change all non-admin passwords to the standard demo password
# heroku run rake db:reset_passwords -a ripple-staging

# TODO deidentify data
