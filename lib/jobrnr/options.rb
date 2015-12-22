module JobRnr
  require 'optparse'
  require 'ostruct'

  class Options
    attr_reader :options

    def initialize
      @options = initialize_options

      default_options(@options)
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
          man_path = File.expand_path(File.join(File.dirname(__FILE__), '../../man/jobrnr.5.ronn'))
          exec "ronn --man #{man_path}"
        end
      end.parse!(argv)

      options
    end

    def initialize_options
      OpenStruct.new
    end

    def default_options(options)
      options.max_jobs = 
        if ENV.key?('JOBRNR_MAX_JOBS') 
          Integer(ENV['JOBRNR_MAX_JOBS']) 
        else
          1
        end

      options.plugin_paths = 
        if ENV.key?('JOBRNR_PLUGIN_PATH')
          ENV['JOBRNR_PLUGIN_PATH'].split(/:/)
        else
          []
        end

      options.dot = false
    end
  end
end
