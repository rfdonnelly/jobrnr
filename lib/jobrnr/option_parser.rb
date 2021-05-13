# frozen_string_literal: true

module Jobrnr
  # Defines the CLI options.
  class OptionParser
    require "optparse"

    attr_reader :options
    attr_reader :parser

    def initialize(argv)
      @options = initialize_options

      options.argv = argv.clone
      default_options(options)
      load_environment(options)

      @parser = create_parser
    end

    def parse(argv)
      parser.parse!(argv)

      options
    end

    def man_path(man_file)
      File.join(__dir__, "../../man", man_file)
    end

    def initialize_options
      Struct.new(
        :argv,
        :dot,
        :max_failures,
        :max_jobs,
        :output_directory,
        :plugin_paths,
        :recycle,
        :verbosity,
      ).new
    end

    def default_options(options)
      options.dot = false
      options.max_failures = 0
      options.max_jobs = 8
      options.output_directory = Dir.pwd
      options.plugin_paths = []
      options.verbosity = 1
      options.recycle = true
    end

    def load_environment(options)
      options.max_failures = Integer(ENV["JOBRNR_MAX_FAILURES"]) if ENV.key?("JOBRNR_MAX_FAILURES")
      options.max_jobs = Integer(ENV["JOBRNR_MAX_JOBS"]) if ENV.key?("JOBRNR_MAX_JOBS")
      options.plugin_paths = ENV["JOBRNR_PLUGIN_PATH"].split(/:/) if ENV.key?("JOBRNR_PLUGIN_PATH")
      options.output_directory = ENV["JOBRNR_OUTPUT_DIRECTORY"] if ENV.key?("JOBRNR_OUTPUT_DIRECTORY")
    end

    def create_parser
      ::OptionParser.new do |op|
        op.banner = "Usage: jobrnr [<option(s)>] <file.jr>"

        op.separator("GENERAL OPTIONS")
        op.on("-v", "--vebose", "Enable debug output.") do
          options.verbosity += 1
        end
        op.on("-d", "--output-directory <directory>",
              "Directory to place results.",
              String) do |arg|
          options.output_directory = arg
        end
        op.on("-f", "--max-failures <failures>",
              "Maximum number of failures before disabling execution of new" \
              " jobs",
              Integer) do |arg|
          options.max_failures = arg
        end
        op.on("-j", "--max-jobs <jobs>",
              "Maximum number of jobs to run simultaneously",
              Integer) do |arg|
          options.max_jobs = arg
        end
        op.on("--no-recycle", "Prevents recycling of job slots") do
          options.recycle = false
        end
        op.separator("")

        op.separator("DEBUG OPTIONS")
        op.on("--dot", "Display job graph in GraphViz DOT format and exit") do
          options.dot = true
        end
        op.separator("")

        op.separator("MISCELLANEOUS OPTIONS")
        op.on("-h", "Display short help (this message)") do
          puts op
          exit
        end
        op.on("--help", "Display long help") do
          exec "man #{man_path('jobrnr.1')}"
        end
        op.on("--help-format", "Display job description file format help") do
          exec "man #{man_path('jobrnr.5')}"
        end
        op.on("--help-plugin", "Display plugin API help and exit.") do
          exec "man #{man_path('jobrnr-plugin.3')}"
        end
        op.on("--version", "Display version") do
          puts "Jobrnr version #{Jobrnr::version}"
          exit
        end
      end
    end

    # Bisects args into two groups to enable command-line options to override
    # job script options.
    #
    # The two groups are:
    #
    # 1. args (lowest precedence)
    # 2. post_args (highest precedence) -- override any options set by the job
    #    script
    #
    # Example:
    #
    # The following args:
    #
    #   -a b -c d -e file +x +y -f g +z -h
    #
    # Are grouped as follows:
    #
    #   * args: -a b -c d -e file +x +y +z
    #   * post_args: -f g -h
    def bisect_args(argv)
      args = []
      post_args = []
      found_file = false
      found_option_after_file = false

      argv.each_with_index do |arg, index|
        if !found_file
          if File.exist?(arg)
            found_file = true
          end
        end

        if found_file && !found_option_after_file
          if arg.start_with?("-")
            found_option_after_file = true
          end
        end

        if found_file && found_option_after_file && !arg.start_with?("+")
          post_args << arg
        else
          args << arg
        end
      end

      [args, post_args]
    end

    # Classifies args remaining after initial parse as filenames or plus
    # options.
    def classify_arguments(argv)
      hash = argv.group_by do |arg|
        if arg[0] == "+"
          :plus_options
        else
          :filenames
        end
      end

      %i[filenames plus_options].map { |key| Array(hash[key]) }
    end

    # Expands any environment variables and possible script-relative path
    def expand_output_directory(user_script_filename)
      expanded_directory = Jobrnr::Util.expand_envars(options.output_directory)
      options.output_directory =
        if Pathname.new(expanded_directory).absolute?
          expanded_directory
        else
          Jobrnr::Util.relative_to_file(expanded_directory, user_script_filename)
        end
    end
  end
end
