# frozen_string_literal: true

module Jobrnr
  # User interface
  class UI
    require "io/console"
    require "pastel"
    require "English"

    attr_reader :color
    attr_reader :ctrl_c
    attr_reader :options
    attr_reader :pool
    attr_reader :slots

    DEFAULT_TIME_SLICE_INTERVAL = 1

    KEYS = Hash.new do |_, k|
      k.chr
    end.merge({
      3 => :ctrl_c,
      13 => :enter,
      26 => :ctrl_z,
    })

    def initialize(options:, pool:, slots:)
      @color = Pastel.new(enabled: $stdout.tty?)
      @ctrl_c = 0
      @options = options
      @pool = pool
      @slots = slots
      @time_slice_interval = Float(ENV.fetch("JOBRNR_TIME_SLICE_INTERVAL", DEFAULT_TIME_SLICE_INTERVAL))
      @instances = []
      @passed = []
      @failed = []

      trapint

      Jobrnr::Log.info "Press '?' for help."
    end

    def pre_instance(inst)
      @instances << inst

      message = [
        "Running:",
        format_command(inst),
      ]

      message << format_slot_with_label(inst)
      message << format_iteration(inst) if inst.job.iterations > 1

      Jobrnr::Log.info message.join(" ")
    end

    def post_instance(inst)
      case inst.success?
      when true
        @passed << inst
      when false
        @failed << inst
      end

      message = [
        format_completion_status(inst),
        format_command(inst),
      ]

      message << format_slot_with_label(inst)
      message << format_iteration(inst) if inst.job.iterations > 1
      message << format_exitcode(inst)

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
      if $stdout.tty?
        process_input
      else
        Kernel.sleep @time_slice_interval
      end
    end

    def stop_submission?
      ctrl_c.positive?
    end

    def parse_integer(type_name, &block)
      n = Integer($stdin.gets)
      block.call(n)
    rescue ::ArgumentError
      warn "could not parse #{type_name}"
    end

    def instance_by_slot(slot, &block)
      inst = @instances.find { |inst| inst.slot == slot }
      if inst.nil?
        warn "invalid slot"
      else
        block.call(inst)
      end
    end

    def restart_instance(inst)
      message = [
        "Restarting:",
        format_command(inst),
      ]

      message << format_slot_with_label(inst)
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
          INSPECT                 JOB CONTROL
          a: List active jobs     i: Interrupt (SIGINT) job
          c: List completed jobs  t: Terminate (SIGTERM) job
          l: List all jobs        k: Kill (SIGKILL) job
          p: List passed jobs     r: Restart job
          f: List failed jobs     j: Modify max-jobs
          o: View output of job

          QUIT
          Ctrl+c (1st): Stop job submission, allow active jobs to finish
          Ctrl+c (2nd): Send SIGINT to active jobs
          Ctrl+c (3rd): Send SIGTERM to active jobs
          Ctrl+c (4th): Send SIGKILL to active jobs
        EOF
      when "a"
        insts = pool
          .instances
          .sort_by(&:start_time)
          .reverse
        print_insts(insts, "active")
      when "c"
        insts = @passed
          .chain(@failed)
          .sort_by(&:end_time)
        print_insts(insts, "completed")
      when "f"
        insts = @failed
          .sort_by(&:end_time)
        print_insts(insts, "failed")
      when "j"
        $stdout.write format("max-jobs (%d): ", slots.size)
        parse_integer("integer") { |n| slots.resize(n) }
      when "i"
        $stdout.write "interrupt (SIGINT) job (slot): "
        parse_integer("slot") { |slot| instance_by_slot(slot, &:sigint) }
      when "k"
        $stdout.write "kill (SIGKILL) job (slot): "
        parse_integer("slot") { |slot| instance_by_slot(slot, &:sigkill) }
      when "l"
        insts = [*@passed, *pool.instances, *@failed]
        print_insts(insts)
      when "o"
        $stdout.write "view output (slot): "
        parse_integer("slot") do |slot|
          instance_by_slot(slot) do |inst|
            cmd = format("tail %s", inst.log)
            $stdout.puts cmd
            system(cmd)
            $stdout.puts
          end
        end
      when "p"
        insts = @passed
          .sort_by(&:end_time)
        print_insts(insts, "passed")
      when "r"
        $stdout.write "restart job (slot): "
        parse_integer("slot") { |slot| instance_by_slot(slot) { |inst| restart_instance(inst) } }
      when "t"
        $stdout.write "terminate (SIGTERM) job (slot): "
        parse_integer("slot") { |slot| instance_by_slot(slot, &:sigterm) }
      end
    end

    def print_insts(insts, type = nil)
      data = insts
        .map do |inst|
          [
            format_slot(inst).capitalize,
            format_active_status(inst),
            format("%ds", inst.duration.round),
            inst.to_s,
          ]
        end.to_a

      if data.empty?
        $stdout.puts ["No", type, "jobs present"].flatten.join(" ")
      else
        $stdout.puts Jobrnr::Table.new(
          header: %w[Slot Status Duration Command],
          rows: data,
        ).render
      end
    end

    def format_active_status(inst)
      if inst.state == :dispatched
        color.yellow("Running")
      elsif inst.success?
        color.green("Passed")
      else
        color.red("Failed")
      end
    end

    def format_completion_status(inst)
      if inst.success?
        color.green("PASSED:")
      else
        color.red("FAILED:")
      end
    end

    def format_command(inst)
      format("'%s'", inst.to_s)
    end

    def format_slot(inst)
      if options.recycle && inst.state == :finished && inst.success?
        "recycled"
      else
        format("%d", inst.slot)
      end
    end

    def format_slot_with_label(inst)
      format("slot:%s", format_slot(inst))
    end

    def format_iteration(inst)
      format("iter:%d", inst.iteration) if inst.job.iterations > 1
    end

    def format_exitcode(inst)
      format("exitcode:%s", inst.exitcode)
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
