# frozen_string_literal: true

module Jobrnr
  # User interface
  class UI
    require "io/console"
    require "pastel"
    require "English"

    attr_reader :color
    attr_reader :ctrl_c
    attr_reader :pool
    attr_reader :slots

    DEFAULT_TIME_SLICE_INTERVAL = 1

    KEYS = Hash.new do |h, k|
      k.chr
    end.merge({
      3 => :ctrl_c,
      13 => :enter,
      26 => :ctrl_z,
    })

    def initialize(pool:, slots:)
      @color = Pastel.new(enabled: $stdout.tty?)
      @ctrl_c = 0
      @pool = pool
      @slots = slots
      @time_slice_interval = Float(ENV.fetch("JOBRNR_TIME_SLICE_INTERVAL", DEFAULT_TIME_SLICE_INTERVAL))

      trapint

      Jobrnr::Log.info "Press '?' for help."
    end

    def pre_instance(inst)
      message = [
        "Running:",
        format_command(inst),
      ]

      message << format_iteration(inst) if inst.job.iterations > 1

      Jobrnr::Log.info message.join(" ")
    end

    def post_instance(inst)
      message = [
        format_status(inst),
        format_command(inst),
      ]

      message << format_iteration(inst) if inst.job.iterations > 1

      message << format("in %#.2fs", inst.duration)

      Jobrnr::Log.info message.join(" ")
    end

    def post_interval(stats)
      Jobrnr::Log.info stats.to_s
    end

    def post_application(early_termination:)
      Jobrnr::Log.info "Early termination due to reaching maximum failures" if early_termination
    end

    def sleep
      process_input
    end

    def stop_submission?
      ctrl_c.positive?
    end

    def parse_integer(type_name, &block)
      begin
        n = Integer($stdin.gets)
        block.call(n)
      rescue ::ArgumentError
        $stdout.puts "could not parse #{type_name}"
      end
    end

    def instance_by_pid(pid, &block)
      inst = pool.instances.find { |inst| inst.pid == pid }
      block.call(inst) unless inst.nil?
    end

    def restart_instance(inst)
      message = [
        "Restarting:",
        format_command(inst),
      ]

      message << format_iteration(inst) if inst.job.iterations > 1

      Jobrnr::Log.info message.join(" ")

      inst.restart
    end

    def process_input
      c = $stdin.getch(min: 0, time: @time_slice_interval)
      return unless c
      case KEYS[c.ord]
      when :ctrl_c
        sigint
      when :ctrl_z
        sigtstp
      when :enter
        # Let the user know we are not hung
        $stdout.puts
      when "?"
        $stdout.puts <<~EOF
          i: Interrupt job
          j: Modify max-jobs
          l: List active jobs
          r: Restart job
          t: Terminate job
        EOF
      when "j"
        $stdout.write format("max-jobs (%d): ", slots.size)
        parse_integer("integer") { |n| slots.resize(n) }
      when "i"
        $stdout.write "interrupt job pid: "
        parse_integer("pid") { |pid| instance_by_pid(pid, &:sigint) }
      when "l"
        data = pool
          .instances
          .sort { |inst| inst.duration }
          .reverse
          .map { |inst| [inst.pid, format("%ds", inst.duration.round), inst.to_s] }
          .to_a
        table = Jobrnr::Table.new(
          header: %w(PID Duration Command),
          rows: data,
        )
        $stdout.puts table.render
      when "r"
        $stdout.write "restart job pid: "
        parse_integer("pid") { |pid| instance_by_pid(pid) { |inst| restart_instance(inst) } }
      when "t"
        $stdout.write "terminate job pid: "
        parse_integer("pid") { |pid| instance_by_pid(pid, &:sigterm) }
      end
    end

    def format_status(inst)
      if inst.success?
        color.green("PASSED:")
      else
        color.red("FAILED:")
      end
    end

    def format_command(inst)
      format(
        "'%<command>s' %<log>s",
        command: inst.to_s,
        log: File.basename(inst.log),
      )
    end

    def format_iteration(inst)
      format("iter:%d", inst.iteration) if inst.job.iterations > 1
    end

    def sigtstp
      Process.kill("TSTP", $PID)
    end

    def trapint
      trap "INT" do
        sigint
      end
    end

    # Handle Ctrl-C
    #
    # On first Ctrl-C, stop submitting new jobs and allow current jobs to
    # finish. On second Ctrl-C, send SIGINT to jobs. On third Ctrl-C, send
    # SIGTERM to jobs. On fourth (and subsequent) Ctrl-C, send SIGKILL to jobs.
    def sigint
      case ctrl_c
      when 0
        Jobrnr::Log.info "Stopping job submission. Allowing active jobs to finish."
        Jobrnr::Log.info "Ctrl-C again to interrupt active jobs with SIGINT."
      when 1
        Jobrnr::Log.info "Interrupting jobs with SIGINT."
        Jobrnr::Log.info "Ctrl-C again to terminate active jobs with SIGTERM."
        pool.sigint
      when 2
        Jobrnr::Log.info "Terminating jobs with SIGTERM."
        Jobrnr::Log.info "Ctrl-C again to kill active jobs with SIGKILL."
        pool.sigterm
      else
        Jobrnr::Log.info "Killing jobs with SIGKILL."
        pool.sigkill
      end

      @ctrl_c += 1
    end
  end
end
