# frozen_string_literal: true

require_relative "lib/jobrnr/version"

Gem::Specification.new do |s|
  s.name = "jobrnr"
  s.version = Jobrnr::VERSION
  s.licenses = ["MIT", "Apache-2.0"]
  s.summary = "Jobrnr runs jobs"
  s.authors = ["Rob Donnelly"]
  s.email = "rfdonnelly@gmail.com"
  s.files = [
    *Dir["lib/**/*"],
    "Rakefile",
    "Gemfile",
  ]

  s.required_ruby_version = ">= 2.7.0"
end
