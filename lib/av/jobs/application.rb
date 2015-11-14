module AV
  module Jobs
    class Application
      JOB_SLOTS = 5

      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def run
        user_script = AV::Jobs::DSL::Loader.evaluate(nil, nil, argv[0])

        AV::Log.debug AV::Jobs::Graph.to_dot

        AV::Jobs::Job::Dispatch.new(
          output_directory: user_script.options.directory,
          graph: AV::Jobs::Graph,
          slots: JOB_SLOTS
        ).run
      end
    end
  end
end
