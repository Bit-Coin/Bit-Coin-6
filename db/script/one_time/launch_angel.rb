
raise 'you probably do not want to run this'

angel = User.find_by_email('arosa1632@gmail.com')
%w(
sburnes@athenahealth.com
aesguerra@athenahealth.com
acrawford@athenahealth.com
lmoore@athenahealth.com
meisenmann@athenahealth.com
mtiffany@athenahealth.com
Tprice@athenahealth.com
Snix@athenahealth.com
Cburgos@athenahealth.com
Bshelly@athenahealth.com
Ttria@athenahealth.com
Pcousins@bidmc.harvard.edu
anatlio@athenahealth.com
nmorabito@athenahealth.com
agroh@athenahealth.com
dpicard@athenahealth.com
rshepler@athenahealth.com
jmack@athenahealth.com
vkourdov@athenahealth.com
ascaplen@athenahealth.com
bnair@athenahealth.com
ceagan@athenahealth.com
jholtschlag@athenahealth.com
Dseltzer@athenahealth.com
Trandall@athenahealth.com
dpatel@athenahealth.com).each do |giver_email|
  puts "Creating invitation for #{giver_email}"
  angel.invitations.build_from_params(receiver: angel, email: giver_email).save
end
