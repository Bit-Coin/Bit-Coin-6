# clean up ugs incorrectly marked unresponsive

list = []
User.unresponsive.each do |u|
  if u.surveys.closed.count > 0
    u.update_attributes(state: 'unregistered_giver')
    list << "#{u.email} #{u.company.name} changed from unresponsive to unregistered_giver"
  end
end
puts list
