module AV
  module Jobs
    module DSL
      class JobCommand
        attr_reader :command
        attr_reader :iterations

        def initialize
          @iterations = 1
        end

        def execute(command = nil, &block)
          if command.nil?
            @command = block
          else
            @command = command
          end
        end

        def repeat(iterations)
          @iterations = iterations
        end
      end
    end
  end
end
