module Jobrnr::Plugin
  class ModifyCommand
    def pre_instance(message)
      # modify the job before it is run
      # add an option
      unless message.instance.command.match(/\s--results-directory\b/)
        results_directory = File.basename(message.instance.log, '.log')
        message.instance.command << " --results-directory #{results_directory}"
      end
    end
  end
end
