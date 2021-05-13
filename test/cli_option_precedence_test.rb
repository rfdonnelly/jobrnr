# frozen_string_literal: true

require "test_helper"

# Options are as follows:
#
# * Pre-options: command-line options before the script
# * Script options: options set by the script
# * Post-options: command-line options after the script
describe "CLI option precedence" do
  describe "pre options" do
    it "set the option" do
      argv = %w[--output-directory a test/fixtures/cli_option_precendence_test/none.rb]
      app = Jobrnr::Application.new(argv)
      app.run
      expect(app.option_parser.options.output_directory).must_equal File.expand_path("a")
    end
  end

  describe "script options" do
    it "overrides command-line options before it" do
      argv = %w[--output-directory a test/fixtures/cli_option_precendence_test/some.rb]
      app = Jobrnr::Application.new(argv)
      app.run
      expect(app.option_parser.options.output_directory).must_equal File.expand_path("b")
    end
  end

  describe "post options" do
    it "overrides script options" do
      argv = %w[--output-directory a test/fixtures/cli_option_precendence_test/some.rb -d c]
      app = Jobrnr::Application.new(argv)
      app.run
      expect(app.option_parser.options.output_directory).must_equal File.expand_path("c")
    end
  end
end
