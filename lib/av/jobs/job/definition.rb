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

        def generate_command
          seed_substitution(evaluate_command)
        end

        def evaluate_command
          if command.respond_to?(:call)
            command.call
          else
            eval('"' + command + '"')
          end
        end

        def seed_substitution(s)
          seed = Random.rand(0xffff_ffff)

          substitutions = [
            [/__SEED%x__/, "0x%08x" % seed],
            [/__SEED%d__/, seed.to_s],
          ]
          substitutions.each_with_object(s) do |substitution, string|
            string.gsub!(*substitution)
          end
        end
      end
    end
  end
end
