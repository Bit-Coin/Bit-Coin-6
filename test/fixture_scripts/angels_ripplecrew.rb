# ripple
puts "Creating Angel's Ripplecrew"

# Teams
company = Team.create!(name: "Angel's Ripplecrew")

# Users
angel = User.create!(
  email: 'arosa1632@gmail.com',
  password: 'gonnaRipple345',
  company_id: company.id,
  cohort: '',
  first_name: 'Angel',
  last_name: 'Rosa',
  confirmed_at: Time.now
)
