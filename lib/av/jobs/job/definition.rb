module AV
  module Jobs
    module Job
      class Definition
        attr_reader :id
        attr_reader :predecessors
        attr_reader :successors
        attr_reader :command
        attr_reader :iterations
        attr_reader :state

        def initialize(id, predecessors, command, iterations)
          @id = id
          @predecessors = predecessors
          @successors = []
          @command = command
          @iterations = iterations
          @state = AV::Jobs::Job::State.new(self, iterations)

          predecessors.each { |p| p.successors.push(self) }
        end

        def evaluate_command
          if command.respond_to?(:call)
            command.call
          else
            eval('"' + command + '"')
          end
        end
      end
    end
  end
end
