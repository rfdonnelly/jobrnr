module AV
  module Jobs
    module Job
      # Transitions
      #
      # :pending => :scheduling => :scheduled => :finished
      class State
        attr_reader :num_scheduled

        def initialize(job, iterations)
          @job = job
          @state = :pending
          @queued = false
          @iterations = iterations
          @num_scheduled = 0
          @num_completed = 0
        end

        def queue
          raise AV::RuntimeError.new("Cannot queue, already queued.\n#{self}") if queued?
          @queued = true
        end

        def schedule
          raise AV::RuntimeError.new("Cannot schedule, already scheduled.\n#{self}") if scheduled?
          @num_scheduled += 1
          @state = :scheduling
          @state = :scheduled if @num_scheduled == @iterations
        end

        def complete
          @num_completed += 1
          @state = :finished if @num_completed == @iterations
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
      end
    end
  end
end
