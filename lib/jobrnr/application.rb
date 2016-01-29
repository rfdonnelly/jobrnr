module Jobrnr
  class Application
    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      options = Jobrnr::Options.new.parse(@argv)
      filename = @argv[0]

      # load plugins
      Jobrnr::Plugins.instance.load(options.plugin_paths)

      user_script = Jobrnr::DSL::Loader.instance.evaluate(nil, nil, filename, options)
      merged_options = merge_options(options, user_script.jobrnr_options, filename)

      if options.dot
        Jobrnr::Log.info Jobrnr::Graph.instance.to_dot
        exit
      end

      Jobrnr::Job::Dispatch.new(
        options: merged_options,
        graph: Jobrnr::Graph.instance,
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
        expanded_directory = Jobrnr::Util.expand_envars(user_script_options.output_directory)
        if expanded_directory[0] != '/'
          Jobrnr::Util.relative_to_file(expanded_directory, user_script_filename)
        else
          expanded_directory
        end
      end
    end
  end
end
