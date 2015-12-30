module JobRnr
  module Job
    class Instance
      attr_reader :job
      attr_reader :slot
      attr_accessor :command
      attr_reader :iteration
      attr_reader :log
      attr_reader :state

      def initialize(job:, slot:, log:)
        @job = job
        @slot = slot
        @log = log
        @command = job.generate_command
        @iteration = job.state.num_scheduled
        @status = nil
        @state = :pending

        @start_time = Time.new
        @end_time = Time.new

        job.state.schedule
      end

      def execute
        @start_time = Time.now
        @state = :dispatched
        @status = system("#{@command} > #{log} 2>&1")
        @state = :finished
        @end_time = Time.now

        job.state.complete

        self
      end

      def duration
        @end_time - @start_time
      end

      def success?
        @status
      end

      def to_s
        @command
      end
    end
  end
end
