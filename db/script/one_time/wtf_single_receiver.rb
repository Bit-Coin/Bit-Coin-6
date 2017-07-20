# Trying to get to the bottom of discrepancy between
# characteristic-level Company Average and Your Scores
# for User 501 and Company 40 (Morales/CareCloud)

cc = Company.find(40)
rm = User.find(501)

puts 'Cleaning and recalculating'
cc.destroy_all_scores
Job::UpdatePersonalScores.perform(rm.id)
Job::UpdateCompanyScores.perform(cc.id)
Job::UpdateSelfScores.perform(rm.id)
puts 'Done'

res = Characteristic.find(1)
csr = Ripple::CharacteristicScoreReporter.new(rm, res)
csr.fetch_all_scores

# compare csr.personal_scores and csr.company_scores
puts "\t\t\tCompany Avg.\tYour Score"
csr.company_scores.each_with_index do |cs, i|
  puts "#{cs[:characteristic][:name]}\t#{cs[:scores][:overall]}\t\
          #{csr.personal_scores[i][:scores][:overall]}"
end
true
