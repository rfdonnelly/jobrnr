module Jobrnr
  module DSL
    class JobBuilder
      def initialize(id:, predecessors:)
        @obj = Jobrnr::Job::Definition.new(id: id, predecessors: predecessors)
      end

      def execute(command = nil, &block)
        if command.nil? && block.nil?
          raise Jobrnr::ArgumentError, "'execute' expects a String or block" \
            " @ #{source}"
        elsif !command.nil? && !block.nil?
          raise Jobrnr::ArgumentError, "'execute' expects a String or block" \
            " not both @ #{source}"
        elsif !command.nil? && !command.is_a?(String)
          raise Jobrnr::ArgumentError, "'execute' expects a String or block" \
            " but was given value of '#{command}' of type" \
            " '#{command.class.name}' @ #{source}"
        end

        @obj.command = command.nil? ? block : command
      end

      def repeat(times)
        if !times.is_a?(Integer) || times < 0
          raise Jobrnr::TypeError, "'repeat' expects a positive Integer" \
            " but was given value of '#{times}' of type" \
            " '#{times.class.name}' @ #{source}"
        end

        @obj.iterations = times
      end

      def source
        caller[2].split(/:/)[0..1].join(':')
      end

      def build
        @obj
      end
    end
  end
end
