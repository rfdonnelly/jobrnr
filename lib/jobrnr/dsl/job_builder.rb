# frozen_string_literal: true

module Jobrnr
  module DSL
    # Defines the commands under the job command: execute and repeat
    class JobBuilder
      def initialize(id:, predecessors:)
        @obj = Jobrnr::Job::Definition.new(id: id, predecessors: predecessors)
      end

      def execute(command = nil, &block)
        if command.nil? && block.nil?
          raise Jobrnr::TypeError, "'execute' expects a String or block " \
                                   "@ #{caller_source}"
        elsif !command.nil? && !block.nil?
          raise Jobrnr::TypeError, "'execute' expects a String or block " \
                                   "not both @ #{caller_source}"
        elsif !command.nil? && !command.is_a?(String)
          raise Jobrnr::TypeError, "'execute' expects a String or block " \
                                   "but was given value of '#{command}' of type " \
                                   "'#{command.class.name}' @ #{caller_source}"
        end

        @obj.command = command.nil? ? block : command
      end

      def repeat(times)
        if !times.is_a?(Integer) || times <= 0
          raise Jobrnr::TypeError, "'repeat' expects an Integer greater than zero " \
                                   "but was given value of '#{times}' of type " \
                                   "'#{times.class.name}' @ #{caller_source}"
        end

        @obj.iterations = times
      end

      def caller_source
        Jobrnr::Util.caller_source(1)
      end

      def build
        if @obj.command.nil?
          raise Jobrnr::ArgumentError,
                "job '#{@obj.id}' is missing required 'execute' command " \
                "@ #{caller_source}"
        end

        @obj
      end
    end
  end
end
