# frozen_string_literal: true

module Jobrnr
  module Job
    # An instance of a job definition.
    #
    # Executes the job.
    class Instance
      attr_reader :job
      attr_reader :slot
      attr_accessor :command
      attr_reader :iteration
      attr_reader :log
      attr_reader :state
      attr_reader :pid

      def initialize(job:, slot:, log:)
        @job = job
        @slot = slot
        @log = log
        @command = job.generate_command
        @iteration = job.state.num_scheduled
        @pid = nil
        @exit_status = nil
        @state = :pending

        @start_time = Time.new
        @end_time = Time.new

        job.state.schedule
      end

      def execute
        @start_time = Time.now
        @state = :dispatched
        # Use spawn with :pgroup => true instead of system to prevent Ctrl+C
        # affecting the command
        @pid = spawn(@command, %i[out err] => log, :pgroup => true)
        @pid, status = Process.waitpid2(pid)
        @exit_status = status.exited? && status.success?
        @state = :finished
        @end_time = Time.now

        job.state.complete(@exit_status)

        self
      end

      def sigint
        return unless state == :dispatched && pid.positive?

        Process.kill("INT", pid)
      end

      def duration
        @end_time - @start_time
      end

      def success?
        @exit_status
      end

      def to_s
        @command
      end
    end
  end
end
