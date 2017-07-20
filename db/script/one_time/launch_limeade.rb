# launch_limeade.rb

puts "Launching Limeade..."
limeade = Company.find_by_stub('limeade')
limeade.members.each do |m|
  puts "#{m.email}"
  CustomDeviseMailer.maven_signed_you_up(m.id).deliver
  m.update_attributes!(last_reminded_at: Time.now)
end
# Henry will get a message saying "Henry signed you up."
