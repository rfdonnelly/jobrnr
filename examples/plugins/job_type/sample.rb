module JobRnr
  module JobType
    class Sample
      def self.pre_process(job_instance)
        # modify the job before it is run
        # add an option
        unless job_instance.command.match(/\s--results-directory\b/)
          results_directory = File.basename(job_instance.log, '.log')
          job_instance.command << " --results-directory #{results_directory}"
        end
      end

      def self.post_process(job_instance)
        # do something special for when a specific option is found
        if job_instance.command.match(/\s--coverage\b/)
          if job_instance.success?
            puts "        doing something special for regr#{job_instance.slot}"
          end
        end
      end

      def self.handles?(command)
        command.match(/.*/)
      end
    end
  end
end
