# frozen_string_literal: true

module Jobrnr
  module Job
    # Defined by the DSL job command.
    # Tracks job state.
    # Template for job instances.
    class Definition
      attr_reader :id
      attr_reader :predecessors
      attr_reader :successors
      attr_accessor :command
      attr_accessor :iterations
      attr_reader :state

      def initialize(id:, predecessors:)
        @id = id
        @predecessors = predecessors
        @successors = []
        @command = nil
        @iterations = 1
        @state = Jobrnr::Job::State.new(self)

        predecessors.each { |p| p.successors.push(self) }
      end

      def generate_command
        seed_substitution(evaluate_command)
      end

      def evaluate_command
        if command.respond_to?(:call)
          command.call
        else
          eval(format('"%s"', command))
        end
      end

      def seed_substitution(s)
        seed = Random.rand(0xffff_ffff)

        substitutions = [
          [/__SEED%x__/, format("%08x", seed)],
          [/__SEED%d__/, seed.to_s],
        ]
        substitutions.each_with_object(s) do |substitution, string|
          string.gsub!(*substitution)
        end
      end
    end
  end
end
