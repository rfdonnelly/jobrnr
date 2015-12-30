module JobRnr
  module Job
    # Transitions
    #
    # :pending => :scheduling => :scheduled => :finished
    class State
      attr_reader :num_scheduled

      def initialize(job)
        @job = job
        @state = :pending
        @queued = false
        @num_scheduled = 0
        @num_completed = 0
      end

      def queue
        fail JobRnr::RuntimeError, "Cannot queue, already queued.\n#{self}" if queued?
        @queued = true
      end

      def schedule
        fail JobRnr::RuntimeError, "Cannot schedule, already scheduled.\n#{self}" if scheduled?
        @num_scheduled += 1
        @state = :scheduling
        @state = :scheduled if @num_scheduled == @job.iterations
      end

      def complete
        @num_completed += 1
        @state = :finished if @num_completed == @job.iterations
      end

      def queued?
        @queued
      end

      def scheduled?
        @state == :scheduled
      end

      def finished?
        @state == :finished
      end

      def to_be_scheduled
        @job.iterations - @num_scheduled
      end
    end
  end
end
