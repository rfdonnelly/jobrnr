# frozen_string_literal: true

module Jobrnr
  # User interface
  class UI
    require "pastel"

    attr_reader :color
    attr_reader :ctrl_c
    attr_reader :pool

    DEFAULT_TIME_SLICE_INTERVAL = 1

    def initialize(pool:)
      @color = Pastel.new(enabled: $stdout.tty?)
      @ctrl_c = 0
      @pool = pool
      @time_slice_interval = Float(ENV.fetch("JOBRNR_TIME_SLICE_INTERVAL", DEFAULT_TIME_SLICE_INTERVAL))

      trap_ctrl_c
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
      Kernel.sleep @time_slice_interval
    end

    def stop_submission?
      ctrl_c.positive?
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

    def trap_ctrl_c
      trap "SIGINT" do
        process_ctrl_c
      end
    end

    # Handle Ctrl-C
    #
    # On first Ctrl-C, stop submitting new jobs and allow current jobs to
    # finish. On second Ctrl-C, send SIGINT to jobs. On third Ctrl-C, send
    # SIGTERM to jobs. On fourth (and subsequent) Ctrl-C, send SIGKILL to jobs.
    def process_ctrl_c
      case ctrl_c
      when 0
        Jobrnr::Log.info "Stopping job submission. Allowing active jobs to finish."
        Jobrnr::Log.info "Ctrl-C again to interrupt (SIGINT) active jobs."
      when 1
        Jobrnr::Log.info "Interrupting (SIGINT) jobs."
        Jobrnr::Log.info "Ctrl-C again to terminate (SIGTERM) active jobs."
        pool.sigint
      when 2
        Jobrnr::Log.info "Terminating (SIGTERM) jobs."
        Jobrnr::Log.info "Ctrl-C again to kill (SIGKILL) active jobs."
        pool.sigterm
      else
        Jobrnr::Log.info "Killing (SIGKILL) jobs."
        pool.sigkill
      end

      @ctrl_c += 1
    end
  end
end
