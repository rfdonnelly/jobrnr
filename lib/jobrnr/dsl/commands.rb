module Jobrnr
  module DSL
    class Commands
      require 'docile'

      attr_reader :jobrnr_options

      def initialize(options)
        @jobrnr_options = options.clone
      end

      def job(id, predecessor_ids = nil, &block)
        valid_jobs = Jobrnr::DSL::Loader.instance.valid_jobs
        prefix = Jobrnr::DSL::Loader.instance.prefix
        return if valid_jobs && !valid_jobs.any? { |valid_job_id| valid_job_id == id }

        predecessors = Array(predecessor_ids).map { |id| Jobrnr::Graph.instance[prefix_id(prefix, id)] }
        builder = Jobrnr::DSL::JobBuilder.new(
          id: prefix_id(prefix, id),
          predecessors: predecessors
        )
        job = Docile.dsl_eval(builder, &block).build
        Jobrnr::Plugins.instance.post_definition(job)
        Jobrnr::Graph.instance.add_job(job)
      end

      def import(prefix, import_jobs, filename)
        expanded_filename = Jobrnr::Util.expand_envars(filename)
        importer_relative = Jobrnr::Util.relative_to_file(expanded_filename, importer_filename)

        load_filename =
          if expanded_filename[0] != '/' && File.exist?(importer_relative)
            importer_relative
          else
            expanded_filename
          end

        jobs_before_import = Jobrnr::Graph.instance.ids.clone
        Jobrnr::DSL::Loader.instance.evaluate(prefix, import_jobs, load_filename, jobrnr_options)
        jobs_after_import = Jobrnr::Graph.instance.ids
        imported_jobs = jobs_after_import.reject { |job| jobs_before_import.include?(job) }

        full_prefix = [Jobrnr::DSL::Loader.instance.prefix, prefix].reject { |item| item.empty? }.join("_")
        jobs_not_imported = import_jobs
          .map { |job| "#{full_prefix}_#{job}".to_sym }
          .reject { |job| imported_jobs.include?(job) }
          .map { |job| job.to_s.match(/^#{full_prefix}_(.*)/).captures.first.to_sym }

        unless jobs_not_imported.empty?
          file_line = caller(1).first.split(/:/)[0..1].join(':')
          fail Jobrnr::ImportError, 
            [
              "Failed to import ids #{jobs_not_imported} from #{filename}",
              "  on import @ #{file_line}"
            ].join("\n")
        end
      end

      def prefix_id(prefix, id)
        if prefix.length > 0
          "#{prefix}_#{id}".to_sym
        else
          id
        end
      end

      def importer_filename
        caller(2)[0].split(/:/).first
      end
    end
  end
end
