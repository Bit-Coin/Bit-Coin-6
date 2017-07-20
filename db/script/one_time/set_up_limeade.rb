# set_up_limeade.rb

# TODO if Limeade already exists, but there aren't any scores, delete everything
# else exit

puts 'Setting up Limeade'
begin
  ActiveRecord::Base.transaction do

    # Create prospect
    jaime = Ripple::OnboardUser.create_prospect('Jaime', 'Ostheimer',
      'jaime.ostheimer@limeade.com', 'Limeade')

    # Create company & plan
    onboarder = Ripple::OnboardUser.new(jaime)
    limeade = onboarder.create_company('Limeade', 'limeade.com', 'limeade')
    subscription = limeade.subscriptions.active_state.first
    company_subscriber = Ripple::Subscription::CompanySubscription.new(subscription)

    # Company settings
    limeade.set_config(:consultant_mode, true)
    limeade.set_config(:reminder_hour, 11) # Pacific time mornings

    # Create CompanySurveySeries (weekly survey generation, Thursday-only reminders, comments: true)
    limeade.use_series(1, {allow_comments: true})
    limeade.use_series(2)

    # Create & register users
    team1_names = [
      ['Ryan', 'Mays', 'ryan.mays@limeade.com'],
      ['Alok', 'Shriram', 'alok.shriram@limeade.com'],
      ['Matthew', 'Tabor', 'matthew.tabor@limeade.com'],
      ['Kevin', 'Schumm', 'kevin.schumm@limeade.com'],
      ['Ngoc', 'Do', 'ngoc.do@limeade.com'],
      ['Megan', 'Plummer', 'megan.plummer@limeade.com'],
      ['David', 'Chen', 'david.chen@limeade.com'],
      ['David', 'Sceppa', 'david.sceppa@limeade.com']
    ]
    team2_names = [
      ['Henry', 'Albrecht', 'henry.albrecht@limeade.com'],
      ['Erick', 'Rivas', 'erick.rivas@limeade.com'],
      ['Laura', 'Hamill', 'laura.hamill@limeade.com'],
      ['Steve', 'Yantorni', 'steve.yantorni@limeade.com'],
      ['Amy', 'Patton', 'amy.patton@limeade.com']
    ]
    teams = {}
    [team1_names, team2_names].each_with_index do |team, i|
      teams[i+1] = []
      team.each do |name|
        puts "Creating #{name[2]}"
        tmp_password = SecureRandom.password
        u = User.create!({
          first_name: name[0],
          last_name: name[1],
          email: name[2],
          company: limeade,
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

    # Take care of Jaime too
    teams[2] << jaime

    # Connect SurveyPlans but DO NOT send intro emails
    puts "Connecting..."
    connector = Ripple::CompanyConnector.new(limeade, nil, limeade.company_survey_series.for_others.active.first)
    connector.join_groups(teams[1], teams[1])
    connector.join_groups(teams[2], teams[2])

    # connect Erick to team1 as well
    erick = User.find_by_email('erick.rivas@limeade.com')
    connector.join_groups([erick], teams[1])

    # connect everyone for self-surveys & set reminder times
    connector = Ripple::CompanyConnector.new(limeade, nil, limeade.company_survey_series.for_self.active.first)
    limeade.users.each do |u|
      connector.join_self(u)
    end
  end
rescue
  puts 'Error setting up Limeade.  Rolled back.'
else
  puts "Upgrading subscription..."
  limeade = Company.find_by_stub('limeade')
  cs = Ripple::Subscription::CompanySubscription.new(limeade.subscriptions.active)
  cs.change_plan('company_1')

  # Generate surveys, but DO NOT remind
  puts "Generating surveys..."
  Job::CreateCompanySurveys.perform(Company.where(stub: 'limeade').collect(&:id))
  puts 'done'
end
