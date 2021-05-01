module Jobrnr
  module Job
    class Pool
      require 'concurrent'

      attr_accessor :futures

      def initialize
        self.futures = []
      end

      def empty?
        self.futures.empty?
      end

      # Removes completed job instances from the pool and returns them
      def remove_completed
        completed_futures = self.futures.select(&:fulfilled?)
        remove_futures(completed_futures)
        completed_futures.map(&:value)
      end

      # Adds job instances to the pool and starts them
      def add_and_start(instances)
        self.futures.concat(create_futures(instances))
      end

      private

      def remove_futures(completed_futures)
        self.futures.reject! { |future| completed_futures.any? { |completed_future| future == completed_future } }
      end

      def create_futures(instances)
        instances.map { |instance| Concurrent::Future.execute { instance.execute } }
      end
    end
  end
end
