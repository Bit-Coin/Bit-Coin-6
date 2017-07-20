puts "Seeding plans"

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'plans.yml')).each do |params|
  Plan.find_or_create_by! params
end

puts "Skipping Stripe plan creation for now"
# Plan.all.each do |plan|
#   if plan.stripe_plan
#     Stripe::Plan.create({
#       :id => plan.name,
#       :amount => (plan.price * 100).to_i,
#       :currency => 'usd',
#       :name => plan.description,
#       :interval => plan.interval,
#       :interval_count => 1,
#       :statement_descriptor => 'RIPPLE ANALYTICS INC'.slice(0, 22), # max 22 chars
#       :metadata => {
#         :ripple_plan_id => plan.id,
#         :metered => plan.metered
#       }
#     })
#     puts "Created stripe plan #{plan.name}"
#   else
#     puts "Created internal plan #{plan.name}"
#   end
# end

puts "Creating trial subscriptions for all existing companies"
free_plan = Plan.find_by_name('free_trial_1')

Company.all.each do |company|
  if company.subscriptions.active
    puts "#{company.name} has an active subscription"
  else
    now = DateTime.now
    subscription = Subscription.create!({
      :team => company,
      :owner => company.manager,
      :start_at => now,
      :end_at => Subscription::FOREVER,
      :state => Subscription::ACTIVE,
      :plan => free_plan
    })
    puts "#{company.name} created subscription"
    print "Adding ripplers to subscription "
    company.users.rippler.each do |user|
      subscription.subscription_users.create!({
        :user => user,
        :start_at => now,
        :end_at => Subscription::FOREVER
      })
      print '. '
    end
    puts " Done"
  end
end

puts "Finished migrating to trial subscriptions"

if Company.count === Subscription.count
  puts "Success. All Companies now have subscriptions."
else
  raise("Something went wrong. Did not create subscriptions for all companies.")
end

if User.rippler.count === SubscriptionUser.count
  puts "Success. All Ripplers now have subscription users."
else
  raise("Something went wrong. Did not create subscription users for all ripplers.")
end

