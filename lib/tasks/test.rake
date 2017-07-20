
# These tasks run individual segments of the test suite

Rails::TestTask.new("test:controllers" => "test:prepare") do |t|
  t.pattern = "test/models/**/*_test.rb"
end
  
Rails::TestTask.new("test:features" => "test:prepare") do |t|
  t.test_files = FileList['test/features/**/*_test.rb']
end

Rails::TestTask.new("test:lib" => "test:prepare") do |t|
  t.pattern = "test/lib/**/*_test.rb"
end

Rails::TestTask.new("test:mailers" => "test:prepare") do |t|
  t.pattern = "test/mailers/**/*_test.rb"
end

Rails::TestTask.new("test:models" => "test:prepare") do |t|
  t.pattern = "test/models/**/*_test.rb"
end

task "test:unit" => ["test:controllers", "test:lib", "test:mailers", "test:models"]

# This is what CI runs
# Due to the way fixtures/transactions work we must run all units first in one process
# and then spin up another process to run all of the feature tests

task 'test:clean' => ["db:setup", "test:prepare"] do
  puts `bundle exec rake test:unit`
  puts `bundle exec rake test:features`
end

Rake::Task["test:run"].clear

task 'test:run' do
  puts "rake test:run is currently broken, as units and features can not be run together"
  puts "use test:unit, test:features, or test:clean"
  puts "To run one test file use 'rake test TEST='path/to/test.rb'"
end