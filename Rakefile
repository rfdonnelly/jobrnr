require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new do |t|
  t.options = %w(--fail-level W)
end

task :default => [:test]
