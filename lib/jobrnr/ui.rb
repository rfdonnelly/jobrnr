# frozen_string_literal: true

module Jobrnr
  # User interface
  class UI
    require "pastel"

    attr_reader :color
    attr_reader :ctrl_c

    TIME_SLICE_INTERVAL = 1

    def initialize
      @color = Pastel.new
      @ctrl_c = 0

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
      Kernel.sleep TIME_SLICE_INTERVAL
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
    # finish. On second Ctrl-C (and beyond), send Ctrl-C to jobs.
    def process_ctrl_c
      case ctrl_c
      when 0
        Jobrnr::Log.info "Stopping job submission. Allowing active jobs to finish."
        Jobrnr::Log.info "Ctrl-C again to terminate active jobs gracefully."
      else
        Jobrnr::Log.info "Terminating by sending Ctrl-C (SIGINT) to jobs."
        Jobrnr::Log.info "Ctrl-C again to send Ctrl-C (SIGINT) again."
        pool.sigint
      end

      @ctrl_c += 1
    end
  end
end
