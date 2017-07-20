require_relative './seeds/admins'

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'characteristics.yml')).each do |params|
  Characteristic.create! params
end

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'plans.yml')).each do |params|
  Plan.create! params
end

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'response_sets.yml')).each do |params|
  ResponseSet.create! params 
end

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'roles.yml')).each do |params|
  Role.create! params 
end

YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'survey_series.yml')).each do |params|
  SurveySeries.create! params 
end

Ripple::SurveyQuestionsImporter.import!('db/seeds/ripple50.csv')
Question.update_all(response_set_id: 1)

Ripple::SurveyQuestionsImporter.import!('db/seeds/project_questions.csv')
