# load responses
print "Seeding response sets"
YAML.load_file(File.join(Rails.root, 'db', 'seeds', 'response_sets.yml')).each do |params|
  if params['id'].present? && !ResponseSet.where('id = ?', params['id']).exists?
    ResponseSet.create! params
    print '.'
  end
end
puts 'done'
standard_responses_id = ResponseSet.first.id

Question.update_all(response_set_id: standard_responses_id)
