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

      JobRnr::Job::Dispatch.new(
        output_directory: user_script.options.directory,
        graph: JobRnr::Graph,
        num_slots: JOB_SLOTS
      ).run
    end
  end
end
