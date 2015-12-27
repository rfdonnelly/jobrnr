module JobRnr
  class Application
    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      options = JobRnr::Options.new.parse(@argv)
      filename = @argv[0]

      if options.dot
        JobRnr::Log.info JobRnr::Graph.instance.to_dot
        exit
      end

      # load plugins
      JobRnr::Plugins.instance.load(options.plugin_paths)

      user_script = JobRnr::DSL::Loader.instance.evaluate(nil, nil, filename)

      directory_option = JobRnr::Util.expand_envars(user_script.options.directory)
      output_directory =
        if directory_option[0] != '/'
          JobRnr::Util.relative_to_file(directory_option, filename)
        else
          directory_option
        end

      JobRnr::Job::Dispatch.new(
        output_directory: output_directory,
        graph: JobRnr::Graph.instance,
        num_slots: options.max_jobs
      ).run
    end
  end
end
