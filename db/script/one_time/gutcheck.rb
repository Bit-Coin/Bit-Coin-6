# gutchecks ridiculous migration

raise "All Ripplers need UserRoles" \
  if User.rippler.where('id not in (?)', UserRole.all.pluck(:user_id)).any?

raise "Shouldn't be any Invitation events" \
  if InvitationEvent.any?

raise "Surveys still need survey sets" \
  if Survey.where('survey_set_id is null').any?

bads = Company.where('stub is null')
if bads.any?
  raise "Missing stub for company #{bads.pluck(:id)}"
end

puts 'Gutcheck OK'
