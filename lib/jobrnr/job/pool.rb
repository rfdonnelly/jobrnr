# frozen_string_literal: true

module Jobrnr
  module Job
    # The job execution pool.
    #
    # Contains all active jobs.
    class Pool
      require "concurrent"

      attr_accessor :instances
      attr_reader :options

      def initialize(options:)
        @options = options
        self.futures = []
        self.instances = []
      end

      def empty?
        futures.empty?
      end

      # Removes completed job instances from the pool and returns them
      def remove_completed
        # Raise any exceptions that occured in the futures
        #
        # If we don't do this, any exceptions that occured in the Futures
        # will be silently ignored and cause Jobrnr to hang since they will
        # never get fullfilled.
        #
        # We don't handle this gracefully because user code cannot cause
        # exceptions here. Any exceptions that occur in futures are due to
        # bad Jobrnr code. We want exceptions in Futures to be "loud".
        futures.select(&:rejected?).map(&:value!)

        completed_futures = futures.select(&:fulfilled?)
        remove_futures(completed_futures)
        completed_instances = completed_futures.map(&:value)
        remove_instances(completed_instances)
        completed_instances
      end

      # Adds job instances to the pool and starts them
      def add_and_start(instances)
        self.instances.concat(instances)
        futures.concat(create_futures(instances))
      end

      %i[sigint sigterm sigkill].each do |method|
        define_method method do
          instances.each(&method)
        end
      end

      private

      attr_accessor :futures

      def remove_futures(completed_futures)
        futures.reject! do |future|
          completed_futures.any? do |completed_future|
            future == completed_future
          end
        end
      end

      def remove_instances(completed_instances)
        instances.reject! do |instance|
          completed_instances.any? do |completed_instance|
            instance == completed_instance
          end
        end
      end

      def create_futures(instances)
        instances.map { |instance| Concurrent::Promises.future { instance.execute(dry_run: options.dry_run) } }
      end
    end
  end
end
