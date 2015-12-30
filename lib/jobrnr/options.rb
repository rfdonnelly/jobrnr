module JobRnr
  require 'optparse'
  require 'ostruct'

  class Options
    attr_reader :options

    def initialize
      @options = initialize_options

      default_options(@options)
      load_environment(@options)
    end

    def parse(argv)
      OptionParser.new do |op|
        op.banner = 'Usage: jobrnr [<option(s)>] <file.jr>'

        op.separator('GENERAL OPTIONS')
        op.on('-j', '--max-jobs <jobs>', 'Maximum number of jobs to run simultaneously') do |arg|
          options.max_jobs = Integer(arg)
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
      JobRnr::Util.relative_to_file(File.join('../../man', man_file), __FILE__)
    end

    def initialize_options
      OpenStruct.new
    end

    def default_options(options)
      options.dot = false
      options.max_jobs = 8
      options.plugin_paths = []
    end

    def load_environment(options)
      options.max_jobs = Integer(ENV['JOBRNR_MAX_JOBS']) if ENV.key?('JOBRNR_MAX_JOBS')
      options.plugin_paths = ENV['JOBRNR_PLUGIN_PATH'].split(/:/) if ENV.key?('JOBRNR_PLUGIN_PATH')
    end
  end
end
