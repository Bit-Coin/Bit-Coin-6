# Useful reporting snippets

company = Company.find(28) # replace with ID of the co you care about

company.all_members.order("id").each do |m|
  ic = Invitation.where("giver_id = ? and state = 'active'", m.id).count
  sf = Survey.for_self.scorable.where("giver_id = ?", m.id).count
  sc = Survey.for_others.scorable.where("giver_id = ?", m.id).count
  la = Survey.for_others.scorable.select("id, giver_id, date(completed_at)"). \
    where("giver_id = ?", m.id). \
    group("giver_id, date(completed_at)"). \
    order("date(completed_at) DESC"). \
    count("id").first
  puts "#{m.id} #{m.full_name}: #{sc} surveys completed (for #{ic} others)" + \
    "#{sf > 0 ? ' +self' : ''} #{la ? la : '[no activity]'}"
end
