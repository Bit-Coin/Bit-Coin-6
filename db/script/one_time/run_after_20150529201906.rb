puts 'Point RES components at parent'
Characteristic.where('id > 1').update_all(parent_characteristic_id: 1)

puts 'Add RES description'
Characteristic.find(1).update_attributes({
  description: "Ripple Effect Score&trade;",
  survey_name: "Ripple Reflection Survey"
})

puts 'Populate survey.parent_characteristic_id'
Survey.update_all(parent_characteristic_id: 1)

puts 'Add performance characteristic'
Characteristic.create!({
  id: 7,
  parent_characteristic_id: nil,
  name: 'performance',
  description: 'Competence. Delivery.',
  survey_name: "Performance Survey",
  icon: 'fa-flag-checkered'
})

puts 'Load yes/no and agree/disagree response sets'
ResponseSet.last.update_attributes(description: 'Never-Always')
ResponseSet.create!({
  id: 2,
  description: 'Yes/No',
  values: { 'yes' => 1, 'no' => 0 }
})
ResponseSet.create!({
  id: 3,
  description: "Strongly Disagree - Strongly Agree",
  values: { 'strongly disagree' => 1, 'disagree' => 2, 'neutral' => 3,
    'agree' => 4, 'strongly agree' => 5 }
})

puts 'Create SurveySeries'
YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'survey_series.yml')).each do |params|
  SurveySeries.create! params 
end

puts 'Fix up SurveySets'
SurveySet.all.each do |s|
  if s.self_survey
    new_name = "Ripple 50, All"
    survey_series_id = 2
  else
    new_name = "Ripple 50, Group #{s.name}"
    survey_series_id = 1
  end
  s.update_attributes!(name: new_name, survey_series_id: survey_series_id)
end

puts 'Create CompanySurveySeries for all Companies'
Company.all.each do |c|
  config = {}
  if c.settings[:accelerated_surveys]
    config.merge!({hours_between_surveys: 24})
  elsif c.settings[:hyperspeed]
    config.merge!({hours_between_surveys: 2})
  end
  config.merge!({allow_comments: true}) if c.settings[:allow_comments]
  c.use_series(1, config)
  c.use_series(2) # self
end

puts 'Creating Roles, UserRoles & SurveyPlans'
YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'roles.yml')).each do |params|
  Role.create! params 
end
User.rippler.each do |u| # regardless of state
  user_role = u.user_roles.create!({role_id: 1, surveyable: u.company})
  u.invitations.each do |inv|
    if inv.giver != inv.receiver
      puts "Migrating Invitation #{inv.id}"
      state = inv.state == 'pending' ? 'new' : inv.state
      css = u.company.company_survey_series.ripple50_others
      sp = SurveyPlan.create!({
        user_role_id: user_role.id,
        company_survey_series: css,
        giver_id: inv.giver_id,
        state: state,
        next_due: inv.hold_until,
        last_reminded_at: inv.reminded_at,
        relationship_type: inv.relationship_type,
        relationship_tags: inv.relationship_tags
      })
      Survey.where('giver_id = ? and receiver_id = ?', 
        inv.giver_id, inv.receiver_id).update_all(survey_plan_id: sp.id)

      # Move events
      inv.invitation_events.update_all({eventable_id: sp.id, eventable_type: 'SurveyPlan'})

      # TODO drop Invitation
    else
      puts "Skipped migrating self-invitation #{inv.id}"
    end
  end

  # self-survey
  if u.active?
    self_surveys = u.surveys.for_self.try(:not_void)
    if self_surveys.any?
      last_self_survey_at = self_surveys.last.created_at # open or closed
    end
    next_due = last_self_survey_at ? last_self_survey_at + 365.days : Time.now
    sp = SurveyPlan.create!({
      user_role_id: user_role.id,
      company_survey_series: u.company.company_survey_series.ripple50_self,
      giver_id: u.id,
      state: 'active',
      next_due: next_due,
      next_survey_set_id: SurveySet.for_self.first.id,
      last_reminded_at: nil
    })
    u.surveys.for_self.update_all(survey_plan_id: sp.id)
  end
  print '.'
end
puts ''

puts 'Load project & role questions/survey set/survey series'
Ripple::SurveyQuestionsImporter.import!('db/seeds/project_questions.csv')
