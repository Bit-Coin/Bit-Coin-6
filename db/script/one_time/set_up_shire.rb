# Set up Shire executive team
#
# Launch parameters - fully connected, Ripple50/50 for self and others
#
# 1 Ripple 50/5-up Ripple 50 questions five at a time
# 2 Ripple 50/50-up Ripple 50 questions all at once
#
# <SurveySeries id: 2, created_at: "2015-07-28 11:26:54", updated_at: "2015-07-28 11:26:54", 
#  name: "Ripple 50/50-up", description: "Ripple 50 questions all at once", 
#  default_config: {"for_self"=>true, "allow_comments"=>false, "hours_between_surveys"=>8760}, 
#  parent_characteristic_id: 1>
# Will transition to Ripple50/5 after first week

puts 'Setting up Shire PLC'
begin
  ActiveRecord::Base.transaction do

    # Create prospect
    frodo = Ripple::OnboardUser.create_prospect('Dan', 'McNamara', 'damcnamara@shire.com', 'Shire PLC')

    # Create company & plan
    onboarder = Ripple::OnboardUser.new(frodo)
    theshire = onboarder.create_company('Shire PLC', 'shire.com', 'shire')
    subscription = theshire.subscriptions.active_state.first
    company_subscriber = Ripple::Subscription::CompanySubscription.new(subscription)

    # Company settings
    theshire.set_config(:consultant_mode, true)
    theshire.set_config(:reminder_hour, 8) # Eastern time mornings

    theshire.use_series(2, {for_self: true, allow_comments: false, hours_between_surveys: 99999, create_manually: true})
    theshire.use_series(2, {for_self: false, allow_comments: true, hours_between_surveys: 99999, create_manually: true})

    # Create & register users
    team1_names = [
      ['Andria', 'Paradis', 'aparadis@shire.com'],
      ['Paul', 'Elson', 'pelson@shire.com'],
      ['Jasmine', 'Daniel', 'jdaniel@shire.com'],
      ['Chris', 'Davis', 'chrdavis@shire.com'],
      ['Cynthia', 'Cassandro', 'ccassandro0@shire.com'],
      ['Nyra', 'Bannis', 'nbannis@shire.com'],
      ['Stephanie', 'MacDonald', 'stmacdonald@shire.com']
    ]

    teams = {}
    [team1_names].each_with_index do |team, i|
      teams[i+1] = []
      team.each do |name|
        puts "Creating #{name[2]}"
        tmp_password = SecureRandom.password
        u = User.create!({
          first_name: name[0],
          last_name: name[1],
          email: name[2],
          company: theshire,
          type: User::RIPPLER,
          state: User::ACTIVE,
          confirmed_at: Time.now,
          password: tmp_password,
          password_confirmation: tmp_password,
          last_reminded_at: Ripple::Time::WHEN_ROBOTS_RULE # suppress reminders
        })
        teams[i+1] << u
        company_subscriber.register_user(u)
      end
    end

    # Take care of Frodo too
    teams[1] << frodo

    # Connect SurveyPlans but DO NOT send intro emails
    puts "Connecting..."
    connector = Ripple::CompanyConnector.new(theshire, nil, theshire.company_survey_series.for_others.active.first)
    connector.join_groups(teams[1], teams[1])

    # connect everyone for self-surveys & set reminder times
    connector = Ripple::CompanyConnector.new(theshire, nil, theshire.company_survey_series.for_self.active.first)
    theshire.users.each do |u|
      connector.join_self(u)
    end
  end
rescue
  puts 'Error setting up Shire PLC.  Rolled back.'
else
  puts "Upgrading subscription..."
  theshire = Company.find_by_stub('shire')
  cs = Ripple::Subscription::CompanySubscription.new(theshire.subscriptions.active)
  cs.change_plan('enterprise_1')

  # Generate surveys, but DO NOT remind
  puts "Generating surveys..."
  theshire = Company.find_by_stub('shire')
  theshire.users.active.each { |u| Resque.enqueue(Job::CreateUserSurveys, u.id) }
  puts "Finished generating surveys"

  puts "Sending Activation Emails"
  # Note: Maven gets an email saying that they signed themselves up
  theshire = Company.find_by_stub('shire')
  theshire.all_members.active.each do |u|
    puts "Activating #{u.email}"
    CustomDeviseMailer.maven_signed_you_up(u.id).deliver
    u.update_attributes!(last_reminded_at: Time.now)
  end
end

puts "Script completed at #{Time.now}"