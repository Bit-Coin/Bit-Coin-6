events = Event.where('eventable_type = ?', 'Message').pluck(:id)
print "Queueing migration for #{events.count} MessageEvent records"
i = 0
events.each do |e|
  i += 1
  Resque.enqueue(Job::OneTime::MigrateEvent, e)
  print "#{i} "
end
puts ''
