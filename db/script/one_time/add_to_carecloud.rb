# Set up CareCloud pilot

# CareCloud CompanySurveySeries values
#
# CSS 38 - SS2 (Ripple 50 questions all at once) - {"for_self"=>true, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 39 - SS 2 (Ripple 50 questions all at once) - {"for_self"=>false, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 40 - SS 6 (CareCloud: 15 questions / 1 survey) - {"for_self"=>false, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 41 - SS 6 (CareCloud: 15 questions / 1 survey) - {"for_self"=>true, "allow_comments"=>false, "hours_between_surveys"=>99999}
begin
ccloud = Company.find_by_domain("carecloud.com")
r50_self = CompanySurveySeries.find(38)
r50_other = CompanySurveySeries.find(39)
cc15_other = CompanySurveySeries.find(40)
cc15_self = CompanySurveySeries.find(41)

# Self-survey connectors - used to join El Guapo to himself
r50_self_conn = Ripple::CompanyConnector.new(ccloud, nil, r50_self)
cc15_self_conn = Ripple::CompanyConnector.new(ccloud, nil, cc15_self)

# Other-survey connectors - used to join The Plethora to El Guapo
r50_other_conn = Ripple::CompanyConnector.new(ccloud, nil, r50_other)
cc15_other_conn = Ripple::CompanyConnector.new(ccloud, nil, cc15_other)

plethora = []

elguapo = User.find_by_email("rmorales@carecloud.com")

albert = User.create!({
  email: 'asantalo@carecloud.com',
  password: User.new(password: SecureRandom.password).encrypted_password,
  first_name: 'Albert',
  last_name: 'Santalo',
  :confirmed_at => Time.now,
  :type => User::RIPPLER,
  :state => User::ACTIVE,
  :company => ccloud
})

plethora << albert

plethora.each do |p|
  puts "Created #{p.id} #{p.full_name} #{p.email}"
end

puts "Adding everybody to the subscription"
subscription = ccloud.subscriptions.active_state.first
company_sub = Ripple::Subscription::CompanySubscription.new(subscription)
plethora.each { |p| company_sub.register_user(p) }

puts "Connecting The Plethora to El Guapo and generating surveys"
ActiveRecord::Base.transaction do
  r50_other_conn.give_to_maven(plethora)
  plethora.each { |p| Job::CreateUserSurveys.perform(p.id) }
end

ActiveRecord::Base.transaction do
  cc15_other_conn.give_to_maven(plethora)
  plethora.each { |p| Job::CreateUserSurveys.perform(p.id) }
end

puts "Sending Activation Emails"
plethora.each do |p|
  puts "Activating #{p.email}"
  CustomDeviseMailer.activate_carecloud_giver(p.id).deliver
  p.update_attributes!(last_reminded_at: Time.now)
end

puts "Finished adding new plethora members"
plethora
end