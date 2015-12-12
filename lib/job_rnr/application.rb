module JobRnr
  class Application
    JOB_SLOTS = 5

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      user_script = JobRnr::DSL::Loader.evaluate(nil, nil, argv[0])

      JobRnr::Log.debug JobRnr::Graph.to_dot

      # load plugins
      if ENV.has_key?('JOBRNR_PLUGIN_PATH')
        paths = ENV['JOBRNR_PLUGIN_PATH'].split(/:/)
        JobRnr::Log.debug "Loading plugins from:\n#{paths.map { |path| "  #{path}" }.join("\n")}"
        JobRnr::Plugins.instance.load(paths)
      end

      JobRnr::Job::Dispatch.new(
        output_directory: user_script.options.directory,
        graph: JobRnr::Graph,
        num_slots: JOB_SLOTS
      ).run
    end
  end
end
