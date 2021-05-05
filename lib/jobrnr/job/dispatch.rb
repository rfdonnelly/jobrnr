# frozen_string_literal: true

module Jobrnr
  module Job
    # Contains the main event loop
    #
    # Runs all jobs in the graph to completion.
    class Dispatch
      require "fileutils"

      attr_reader :options
      attr_reader :graph
      attr_reader :slots
      attr_reader :job_queue
      attr_reader :pool
      attr_reader :stats
      attr_reader :plugins
      attr_reader :ui

      def initialize(options:, graph:, ui:, stats:, slots:)
        @options = options
        @graph = graph
        @ui = ui
        @slots = slots
        @stats = stats
        @plugins = Jobrnr::Plugins.instance
        @job_queue = []
        @pool = Jobrnr::Job::Pool.new
      end

      def prerequisites_met?(job)
        job.predecessors.all? { |predecessor| predecessor.state.finished? && predecessor.state.passed? }
      end

      def done?(job_queue, job_pool)
        (job_queue.empty? || stop_submission?) && job_pool.empty?
      end

      def stop_submission?
        max_failures_reached || ui.stop_submission?
      end

      def nothing_todo?(completed, job_queue, slots)
        completed.empty? && (
          job_queue.empty? ||
          slots.available <= 0 ||
          stop_submission?
        )
      end

      def ready_to_queue(successors)
        successors.select { |successor| !successor.state.queued? && prerequisites_met?(successor) }
      end

      def enqueue(*jobs)
        stats.enqueue(*jobs)
        job_queue.push(*jobs)
      end

      def run
        cummulative_completed_instances = []

        enqueue(*graph.roots)

        FileUtils.mkdir_p(options.output_directory)

        until done?(job_queue, pool)
          completed = pool.remove_completed

          if nothing_todo?(completed, job_queue, slots)
            # skip this interval
            ui.sleep
            next
          end

          # process completed job instances
          cummulative_completed_instances.push(*completed)
          completed.each do |job_instance|
            ui.post_instance(job_instance)
            stats.post_instance(job_instance)
            plugins.post_instance(Jobrnr::PostInstanceMessage.new(job_instance, options))

            # find new jobs to be queued
            if job_instance.success? && job_instance.job.state.finished?
              successors_to_queue = ready_to_queue(job_instance.job.successors)
              successors_to_queue.each { |successor| successor.state.queue }
              enqueue(*successors_to_queue)
            end

            slots.deallocate(job_instance.slot, options.recycle && job_instance.success?)
          end

          # launch new job instances
          new_instances = stop_submission? ? [] : process_queue(job_queue)
          pool.add_and_start(new_instances)

          ui.post_interval(stats)
          plugins.post_interval(Jobrnr::PostIntervalMessage.new(completed, new_instances, stats, options))

          ui.sleep
        end

        status_code = stats.failed
        plugins.post_application(
          Jobrnr::PostApplicationMessage.new(
            status_code,
            cummulative_completed_instances,
            stats,
            options
          )
        )
        ui.post_application(
          early_termination: max_failures_reached && !job_queue.empty?
        )

        status_code
      end

      def max_failures_reached
        options.max_failures.positive? && stats.failed >= options.max_failures
      end

      def process_queue(job_queue)
        num_jobs_queued = [*job_queue.map(&:state).map(&:to_be_scheduled), 0].reduce(&:+)
        num_to_schedule = [num_jobs_queued, slots.available].min

        num_to_schedule.times.map do
          slot = slots.allocate
          job_instance = Jobrnr::Job::Instance.new(
            job: job_queue.first,
            slot: slot,
            log: log_filename(slot)
          )

          # remove job from queue if all instances scheduled otherwise send to
          # the back of the queue to play fair with other jobs
          if job_instance.job.state.scheduled?
            job_queue.shift
          else
            job_queue.rotate!
          end

          plugins.pre_instance(Jobrnr::PreInstanceMessage.new(job_instance, options))
          ui.pre_instance(job_instance)
          stats.pre_instance

          job_instance
        end
      end

      def log_filename(slot)
        File.join(
          options.output_directory,
          format("%<dirname>s%<slot_id>02d", dirname: File.basename(options.output_directory), slot_id: slot)
        )
      end
    end
  end
end
