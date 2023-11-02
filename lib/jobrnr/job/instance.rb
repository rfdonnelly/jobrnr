# frozen_string_literal: true

module Jobrnr
  module Job
    require "shellwords"

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

      attr_reader :start_time
      attr_reader :end_time

      def initialize(job:, slot:, log:)
        @job = job
        @slot = slot
        @log = log
        @command = job.generate_command
        @iteration = job.state.num_scheduled
        @pid = nil
        @exit_status = nil
        @exit_code = nil
        @state = :pending
        @execute = true

        @start_time = Time.new
        @end_time = Time.new

        job.state.schedule
      end

      def execute
        status = nil

        # Loop to enable restart feature
        while @execute
          @execute = false
          @start_time = Time.now
          @state = :dispatched

          # Use spawn with :pgroup => true instead of system to prevent Ctrl+C
          # affecting the command.
          # Use spawn(3) instead of spawn(1) to prevent an intermediate
          # subshell (i.e. sh -c command).  An intermediate subshell interferes
          # with passing signals to the child process.
          # Use spawn(3) instead of spawn(2) because sometimes we have
          # arguments and sometimes we don't.  When no args, we need to use
          # spawn(3) otherwise spawn(1) will be used.  In other words, there
          # is no way spawn(2) w/o args.
          # Since we are using spawn(3), we don't get a subshell and the
          # shell's handling of args so we need to do this using Shellwords.
          command, *argv = Shellwords.split(@command)
          @pid = spawn([command, command], *argv, %i[out err] => log, :pgroup => true)
          @pid, status = Process.waitpid2(pid)
        end

        @exit_status = status.exited? && status.success?
        @exit_code = status.exitstatus
        @state = :finished
        @end_time = Time.now

        job.state.complete(@exit_status)

        self
      end

      %i[sigint sigterm sigkill].each do |method|
        define_method method do
          return unless state == :dispatched && pid.positive?

          Process.kill(method.upcase, pid)
        end
      end

      def restart
        sigterm
        @execute = true
      end

      def duration
        case state
        when :pending
          0
        when :dispatched
          Time.now - @start_time
        when :finished
          @end_time - @start_time
        end
      end

      def success?
        @exit_status
      end

      def exitcode
        if @exit_code.nil?
          "n/a"
        else
          @exit_code.to_s
        end
      end

      def to_s
        @command
      end
    end
  end
end
