# frozen_string_literal: true

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new do |t|
  t.options = %w[--fail-level W]
end

task :man do
  require 'asciidoctor'
  files = FileList["man/*.adoc"]
  files.each do |file|
    Asciidoctor.convert_file(
      file,
      safe: :unsafe,
      backend: 'manpage',
    )
  end
end

task :default => [:man, :test]
