# frozen_string_literal: true

module Jobrnr
  module Job
    class Pool
      require 'concurrent'

      def initialize
        self.futures = []
        self.instances = []
      end

      def empty?
        self.futures.empty?
      end

      # Removes completed job instances from the pool and returns them
      def remove_completed
        completed_futures = self.futures.select(&:fulfilled?)
        remove_futures(completed_futures)
        completed_instances = completed_futures.map(&:value)
        remove_instances(completed_instances)
        completed_instances
      end

      # Adds job instances to the pool and starts them
      def add_and_start(instances)
        self.instances.concat(instances)
        self.futures.concat(create_futures(instances))
      end

      def sigint
        self.instances.each(&:sigint)
      end

      private

      attr_accessor :futures
      attr_accessor :instances

      def remove_futures(completed_futures)
        self.futures.reject! { |future| completed_futures.any? { |completed_future| future == completed_future } }
      end

      def remove_instances(completed_instances)
        self.instances.reject! { |instance| completed_instances.any? { |completed_instance| instance == completed_instance } }
      end

      def create_futures(instances)
        instances.map { |instance| Concurrent::Promises.future { instance.execute } }
      end
    end
  end
end
