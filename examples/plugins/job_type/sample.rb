module JobRnr
  module Plugin
    class Sample
      def pre_instance(message)
        # modify the job before it is run
        # add an option
        unless message.instance.command.match(/\s--results-directory\b/)
          results_directory = File.basename(message.instance.log, '.log')
          message.instance.command << " --results-directory #{results_directory}"
        end
      end

      def post_instance(message)
        # do something special for when a specific option is found
        if message.instance.command.match(/\s--coverage\b/)
          results_directory = File.basename(message.instance.log, '.log')
          if message.instance.success?
            puts "        doing something special for #{results_directory}"
          end
        end
      end
    end
  end
end
