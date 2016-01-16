module Jobrnr
  module DSL
    class JobBuilder
      def initialize(id:, predecessors:)
        @obj = Jobrnr::Job::Definition.new(id: id, predecessors: predecessors)
      end

      def execute(command = nil, &block)
        if command.nil?
          @obj.command = block
        else
          @obj.command = command
        end
      end

      def repeat(times)
        @obj.iterations = times
      end

      def build
        @obj
      end
    end
  end
end
