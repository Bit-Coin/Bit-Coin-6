# Script to add new users to Norwell Athletic and rebuild all SurveyPlans

puts "Making adjustments to Norwell"

# Company setup details
thecompany = Company.find_by_stub('norwell')
thename = thecompany.name
thedomain = thecompany.domain
thestub = thecompany.stub

new_users = []

begin
  ActiveRecord::Base.transaction do

    theboss = thecompany.manager
    subscription = thecompany.subscriptions.active_state.first
    company_subscriber = Ripple::Subscription::CompanySubscription.new(subscription)

    # Apply company settings
    thecompany.set_config(:consultant_mode, true) # members cannot invite new people
    thecompany.set_config(:reminder_hour, 8) # Eastern time mornings

    # Construct an array of all existing team members
    existing_team = []
    thecompany.all_members.active.each { |u| existing_team << u }

    # Create and register additional users
    # Format: array of arrays of the form [ 'first_name', 'last_name', 'email' ]

    team1_names = [
      [ "Lindsey", "O'Leary", "loleary@norwellathleticclub.com"  ],
      [ "Kelly",   "Holland", "kholland@norwellathleticclub.com" ]
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
          company: thecompany,
          type: User::RIPPLER,
          state: User::ACTIVE,
          confirmed_at: Time.now,
          password: tmp_password,
          password_confirmation: tmp_password,
          last_reminded_at: Ripple::Time::WHEN_ROBOTS_RULE # suppress reminders
        })
        teams[i+1] << u
        new_users << u
        company_subscriber.register_user(u)
      end
    end

    # Include the existing users - everybody is in team[1] after this
    existing_team.each { |u| teams[1] << u }

    # Connect SurveyPlans but DO NOT send intro emails
    puts "Connecting..."
    # Fully connect the group
    thesurveyseries = CompanySurveySeries.find(37) # Ripple 50 for others, all at once, manually create
    connector = Ripple::CompanyConnector.new(thecompany, nil, thesurveyseries)
    connector.join_groups(teams[1], teams[1])

    # give everybody a self-survey plan
    connector = Ripple::CompanyConnector.new(thecompany, nil, thecompany.company_survey_series.for_self.active.first)
    teams[1].each do |u|
      connector.join_self(u)
    end
  end
rescue
  puts 'Norwell reconfiguration script failed. Txn rolled back.'
else
  puts "Upgrading subscription..."
  thecompany = Company.find_by_stub(thestub)
  cs = Ripple::Subscription::CompanySubscription.new(thecompany.subscriptions.active)
  cs.change_plan('enterprise_1')

  # Generate surveys, but DO NOT remind
  puts "Generating surveys..."
  thecompany = Company.find_by_stub(thestub)
  thecompany.users.active.each { |u| Resque.enqueue(Job::CreateUserSurveys, u.id) }
  puts "Finished generating surveys"

  puts "Sending Activation Emails to New Users ONLY"
  thecompany = Company.find_by_stub(thestub)
  new_users.each do |u|
    puts "Activating #{u.email}"
    CustomDeviseMailer.maven_signed_you_up(u.id).deliver
    u.update_attributes!(last_reminded_at: Time.now)
  end
  
  "Script completed at #{Time.now}"
end
