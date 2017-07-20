# Hard-code some nice subdomain stubs for all our existing customers
# Run this after 20150528194058_add_stub_to_company.rb

puts "Assigning managers and stubs..."
stubs = [
  [9, "angel"], 
  [10, "athena"], 
  [15, "unfcu"], 
  [1, "acme"], 
  [5, "ripple"], 
  [11, "plm"], 
  [27, "sunil"], 
  [28, "onemind"], 
  [30, "colliers"], 
  [31, "ngkf"], 
  [32, "anil"],
  [33, "nevins"],
  [35, "winebow"],
  [36, "target"]
]

stubs.each do |s|
  c = Company.find(s[0])

  manager = c.members.first if c.members.any? && c.manager.blank?
  c.manager ||= manager
  c.stub = s[1]
  c.save!
  puts "Assigned #{"manager and " if manager }stub for company #{s[0]}"
end
