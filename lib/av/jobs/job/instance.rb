module AV
  module Jobs
    module Job
      class Instance
        attr_reader :job
        attr_reader :slot
        attr_reader :command
        attr_reader :iteration
        attr_reader :log

        def initialize(job:, slot:, log:)
          @job = job
          @slot = slot
          @log = log
          @command = job.evaluate_command
          @iteration = job.state.num_scheduled
          @status = nil

          @start_time = Time.new
          @end_time = Time.new

          job.state.schedule
        end

        def execute
          @start_time = Time.now

          @status = system("echo #{@command} > #{log}")

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
end
