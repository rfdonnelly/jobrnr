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

      user_script = JobRnr::DSL::Loader.instance.evaluate(nil, nil, filename, options)
      merged_options = merge_options(options, user_script.options, filename)

      JobRnr::Job::Dispatch.new(
        options: merged_options,
        graph: JobRnr::Graph.instance,
        num_slots: options.max_jobs
      ).run
    end

    def merge_options(global_options, user_script_options, user_script_filename)
      merged_options = user_script_options.clone

      merged_options.output_directory = get_output_directory(global_options, user_script_options, user_script_filename)

      merged_options
    end

    def get_output_directory(global_options, user_script_options, user_script_filename)
      if user_script_options.output_directory.nil?
        global_options.output_directory
      else
        expanded_directory = JobRnr::Util.expand_envars(user_script_options.output_directory)
        if expanded_directory[0] != '/'
          JobRnr::Util.relative_to_file(expanded_directory, user_script_filename)
        else
          expanded_directory
        end
      end
    end
  end
end
