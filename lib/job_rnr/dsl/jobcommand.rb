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

        # enable use of methods defined in script scope
        #
        # For example, this enables use of 'tests' method in the following
        # example user script.  'tests' is a method of the user script class.
        # Code in 'execute' block only has access to JobCommand methods.  Any
        # unrecognized JobCommand method (i.e. call to 'tests' method) will be
        # passed to method_missing and then passed up to the user script.
        #
        # def tests
        #   %w(test0 test1)
        # end
        #
        # job :test do
        #   execute do
        #     "echo #{tests.sample}"
        #   end
        # end
        def method_missing(method_sym, *arguments, &block)
          script_obj = AV::Jobs::DSL::Loader.script
          script_obj.send(method_sym, *arguments, &block)
        end

        def respond_to_missing?(method_sym, include_private = false)
          script_obj = AV::Jobs::DSL::Loader.script
          script_obj.respond_to?(method_sym, include_private)
        end
      end
    end
  end
end
