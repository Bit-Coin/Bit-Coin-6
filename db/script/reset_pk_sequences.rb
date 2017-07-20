# reset_pk_sequences.rb

puts "Resetting pk sequences..."
ActiveRecord::Base.connection.tables.each do |t|
  puts t
  ActiveRecord::Base.connection.reset_pk_sequence!(t)
end
