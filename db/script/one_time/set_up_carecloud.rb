# Set up CareCloud pilot

# CareCloud CompanySurveySeries values
#
# CSS 38 - SS2 (Ripple 50 questions all at once) - {"for_self"=>true, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 39 - SS 2 (Ripple 50 questions all at once) - {"for_self"=>false, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 40 - SS 6 (CareCloud: 15 questions / 1 survey) - {"for_self"=>false, "allow_comments"=>false, "hours_between_surveys"=>99999}
# CSS 41 - SS 6 (CareCloud: 15 questions / 1 survey) - {"for_self"=>true, "allow_comments"=>false, "hours_between_surveys"=>99999}

ccloud = Company.find(40)
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

puts "Setting up El Guapo"
elguapo = nil
ActiveRecord::Base.transaction do
  elguapo = User.create!({
    email: 'rmorales@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Ricardo',
    last_name: 'Morales',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  ccloud.update_attributes(manager: elguapo)
  ccloud.subscriptions.first.update_attributes(owner: elguapo)

  r50_self_conn.join_self(elguapo)
  cc15_self_conn.join_self(elguapo)
end

puts "Setting up The Plethora"
plethora = []
ActiveRecord::Base.transaction do
  u01 = User.create!({
    email: 'atoro@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Adam',
    last_name: 'Toro',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u01

  u02 = User.create!({
    email: 'cfares@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Carlos',
    last_name: 'Fares',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u02

  u03 = User.create!({
    email: 'epiloto@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Ernesto',
    last_name: 'Piloto',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u03

  u04 = User.create!({
    email: 'jyeung@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Joe',
    last_name: 'Yeung',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u04

  u05 = User.create!({
    email: 'bmciver@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Bill',
    last_name: 'McIver',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u05

  u06 = User.create!({
    email: 'jcummings@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Jeff',
    last_name: 'Cummings',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u06

  u07 = User.create!({
    email: 'mcuesta@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Mike',
    last_name: 'Cuesta',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u07

  u08 = User.create!({
    email: 'lhorner@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Lee',
    last_name: 'Horner',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u08

  u09 = User.create!({
    email: 'rcatalano@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Ralph',
    last_name: 'Catalano',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u09

  u10 = User.create!({
    email: 'smenon@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Sree',
    last_name: 'Menon',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u10

  u11 = User.create!({
    email: 'slink@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Steve',
    last_name: 'Link',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u11

  u12 = User.create!({
    email: 'prowland@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Patrick',
    last_name: 'Rowland',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u12

  u13 = User.create!({
    email: 'dpadilla@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Dianna',
    last_name: 'Padilla',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u13

  u14 = User.create!({
    email: 'shughes@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Sarah',
    last_name: 'Hughes',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u14

  u15 = User.create!({
    email: 'jsiegel@carecloud.com',
    password: User.new(password: SecureRandom.password).encrypted_password,
    first_name: 'Josh',
    last_name: 'Siegel',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => ccloud
  })

  plethora << u15
end

plethora.each do |p|
  puts "Created #{p.id} #{p.full_name} #{p.email}"
end

puts "Adding everybody to the subscription"
subscription = ccloud.subscriptions.active_state.first
company_sub = Ripple::Subscription::CompanySubscription.new(subscription)
company_sub.register_user(elguapo)
plethora.each { |p| company_sub.register_user(p) }

puts "Connecting The Plethora to El Guapo"
r50_other_conn.give_to_maven(plethora)
cc15_other_conn.give_to_maven(plethora)

puts "Generating Surveys"
ccloud.users.active.each { |u| Resque.enqueue(Job::CreateUserSurveys, u.id) }

puts "Sending Activation Emails"
plethora.each do |p|
  puts "Activating #{p.email}"
  CustomDeviseMailer.activate_carecloud_giver(p.id).deliver
  p.update_attributes!(last_reminded_at: Time.now)
end

CustomDeviseMailer.activate_carecloud_receiver(elguapo.id).deliver
elguapo.update_attributes!(last_reminded_at: Time.now)

puts "Finished activating CareCloud pilot!"