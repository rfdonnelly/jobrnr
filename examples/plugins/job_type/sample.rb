module JobRnr
  module Plugin
    class Sample
      def pre_instance(instance)
        # modify the job before it is run
        # add an option
        unless instance.command.match(/\s--results-directory\b/)
          results_directory = File.basename(instance.log, '.log')
          instance.command << " --results-directory #{results_directory}"
        end
      end

      def post_instance(instance)
        # do something special for when a specific option is found
        if instance.command.match(/\s--coverage\b/)
          if instance.success?
            puts "        doing something special for regr#{instance.slot}"
          end
        end
      end
    end
  end
end
