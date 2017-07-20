# Create default administrator account (non-prod only)

unless Rails.env.production?
  puts 'Creating admin accounts'
  Admin.create!(
    email: 'demo+admin@ripplecrew.com',
    password: Security::DEMO_PASSWORD,
    first_name: 'Thor',
    last_name: 'Thegodofthunder'
  )
end
