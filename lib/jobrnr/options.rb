module Jobrnr
  require 'optparse'

  class Options
    attr_reader :options

    def initialize
      @options = initialize_options

      default_options(@options)
      load_environment(@options)
    end

    def parse(argv)
      options.argv = argv.clone

      ::OptionParser.new do |op|
        op.banner = 'Usage: jobrnr [<option(s)>] <file.jr>'

        op.separator('GENERAL OPTIONS')
        op.on('-d', '--output-directory <directory>',
              'Directory to place results.',
              String) do |arg|
          options.output_directory = arg
        end
        op.on('-f', '--max-failures <failures>',
              'Maximum number of failures before disabling execution of new' \
              ' jobs',
              Integer) do |arg|
          options.max_failures = arg
        end
        op.on('-j', '--max-jobs <jobs>',
              'Maximum number of jobs to run simultaneously',
              Integer) do |arg|
          options.max_jobs = arg
        end
        op.separator('')

        op.separator('DEBUG OPTIONS')
        op.on('--dot', 'Display job graph in GraphViz DOT format and exit') do
          options.dot = true
        end
        op.separator('')

        op.separator('MISCELLANEOUS OPTIONS')
        op.on('-h', 'Display short help (this message)') do
          puts op
          exit
        end
        op.on('--help', 'Display long help') do
          exec "ronn --man #{man_path('jobrnr.1.ronn')}"
        end
        op.on('--help-format', 'Display job description file format help') do
          exec "ronn --man #{man_path('jobrnr.5.ronn')}"
        end
        op.on('--help-plugin', 'Display plugin API help and exit.') do
          exec "ronn --man #{man_path('jobrnr-plugin.3.ronn')}"
        end
      end.parse!(argv)

      options
    end

    def man_path(man_file)
      Jobrnr::Util.relative_to_file(File.join('../../man', man_file), __FILE__)
    end

    def initialize_options
      Struct.new(
        :argv,
        :dot,
        :max_failures,
        :max_jobs,
        :output_directory,
        :plugin_paths
      ).new
    end

    def default_options(options)
      options.dot = false
      options.max_failures = 0
      options.max_jobs = 8
      options.output_directory = Dir.pwd
      options.plugin_paths = []
    end

    def load_environment(options)
      options.max_failures = Integer(ENV['JOBRNR_MAX_FAILURES']) if ENV.key?('JOBRNR_MAX_FAILURES')
      options.max_jobs = Integer(ENV['JOBRNR_MAX_JOBS']) if ENV.key?('JOBRNR_MAX_JOBS')
      options.plugin_paths = ENV['JOBRNR_PLUGIN_PATH'].split(/:/) if ENV.key?('JOBRNR_PLUGIN_PATH')
      options.output_directory = ENV['JOBRNR_OUTPUT_DIRECTORY'] if ENV.key?('JOBRNR_OUTPUT_DIRECTORY')
    end
  end
end
