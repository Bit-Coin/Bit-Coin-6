# Set up Fannie Mae pilot

puts "Setting up Fannie Mae"
ActiveRecord::Base.transaction do
  cm = Characteristic.create!({
    name: 'Effective, Admired Leader',
    survey_name: "Effective, Admired Leader Survey",
    score_name: "Effective, Admired Leader Score",
    icon: 'fa-bullseye'
  })
  Characteristic.create!({
    name: 'leadership_credibility_index',
    description: "Leadership Credibility Index",
    icon: 'fa-bullseye',
    parent_characteristic_id: cm.id
  })    
  Characteristic.create!({
    name: 'general_credibility_index',
    description: "General Credibility Index",
    icon: 'fa-bullseye',
    parent_characteristic_id: cm.id
  })

  ss = SurveySeries.create!({
    name: 'EAL/20-up',
    description: "Effective Admired Leader Questions",
    default_config: { hours_between_surveys: 2160, for_self: false, allow_comments: true },
    parent_characteristic_id: cm.id
  })
  Ripple::SurveyQuestionsImporter.import_fannie_mae!('db/seeds/lll_questions.csv', ss.id)

  fannie = Company.create!({
    name: 'Fannie Mae', 
    domain: 'fanniemae.com',
    type: 'pilot',
    stub: 'fanniemae'
  })
  fannie.use_series(ss.id)
  fannie.use_series(ss.id, {for_self: true, allow_comments: false})
  fannie.set_config(:consultant_mode, true)

  # subscription

  lisa = User.create!({
    email: 'lisa@listenlearnleadllc.com',
    password: Security::DEMO_PASSWORD,
    first_name: 'Lisa',
    last_name: 'Mascolo',
    :confirmed_at => Time.now,
    :type => User::RIPPLER,
    :state => User::ACTIVE,
    :company => fannie
  })

  fannie.update_attributes(manager: lisa)

  subscription = fannie.subscriptions.create!({
    plan_id: 1,
    start_at: Date.today,
    end_at: Subscription::FOREVER,
    state: Subscription::ACTIVE,
    owner: lisa
  })
  cs = Ripple::Subscription::CompanySubscription.new(subscription)
  cs.register_user(lisa)

  unless Rails.env.production?
    puts 'Creating fake Fannie Mae data'
    require File.join(Rails.root, 'test', 'fixtures', 'fannie_helper.rb')
    FannieHelper.make_it_so
  end
end
