# frozen_string_literal: true

module Jobrnr
  module Plugin
    # The ModifyCommand plugin conditionally modifies the job command before it
    # is executed.
    class ModifyCommand
      def pre_instance(message)
        # Add the --results-directory option to the command if not already
        # present
        return if message.instance.command.match(/\s--results-directory\b/)

        results_directory = File.basename(message.instance.log, ".log")
        message.instance.command << " --results-directory #{results_directory}"
      end
    end
  end
end
