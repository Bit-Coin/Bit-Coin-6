# ripple
puts 'Creating Ripple account'

# Company & Teams
company = Company.create!(name: 'Ripple Analytics Inc.', domain: 'ripplecrew.com', stub: 'ripple')
bd = company.teams.create!(name: 'Business Development')
ops = company.teams.create!(name: 'Operations')
engineering = company.teams.create!(name: 'Engineering')

# Users
ceo = User.create!(
  email: 'noah@ripplecrew.com',
  password: Security::DEMO_PASSWORD,
  company_id: company.id,
  cohort: 'Manager',
  first_name: 'Noah',
  last_name: 'Pusey',
  confirmed_at: Time.now,
  type: 'rippler',
  state: 'active'
)
company.manager = ceo
company.save

ops_manager = User.create!(
  email: 'tom@ripplecrew.com',
  password: Security::DEMO_PASSWORD,
  team_id: ops.id,
  company_id: company.id,
  cohort: 'Manager',
  first_name: 'Tom',
  last_name: 'Cady',
  confirmed_at: Time.now,
  type: 'rippler',
  state: 'active'
)
ops.manager = ops_manager
ops.save

bob = User.create!(
  email: 'bob@ripplecrew.com',
  password: Security::DEMO_PASSWORD,
  team_id: engineering.id,
  company_id: company.id,
  cohort: 'Manager',
  first_name: 'Bob',
  last_name: 'Gatewood',
  confirmed_at: Time.now,
  type: 'rippler',
  state: 'active'
)
engineering.manager = bob
engineering.save

sean = User.create!(
  email: 'sean@ripplecrew.com',
  password: Security::DEMO_PASSWORD,
  team_id: engineering.id,
  company_id: company.id,
  cohort: 'Manager',
  first_name: 'Sean',
  last_name: 'Molley',
  confirmed_at: Time.now,
  type: 'rippler',
  state: 'active'
)

max = User.create!(
  email: 'max@ripplecrew.com',
  password: Security::DEMO_PASSWORD,
  team_id: engineering.id,
  company_id: company.id,
  cohort: 'Manager',
  first_name: 'Max',
  last_name: 'Lord',
  confirmed_at: Time.now,
  type: 'rippler',
  state: 'active'
)

start_date = (Date.today - 60.days).to_datetime
subscription = Subscription.create({
  company_id: company.id,
  plan_id: 1, # free 
  start_at: start_date,
  end_at: Subscription::FOREVER,
  state: Subscription::ACTIVE,
  owner: bob
})

company.all_members.each do |u|
  subscription.subscription_users.create({
    user: u,
    start_at: start_date,
    end_at: Subscription::FOREVER
  })
end

# set up company survey series
company.use_series(1)
company.use_series(2)
