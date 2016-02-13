module Jobrnr
  module DSL
    class Commands
      require 'docile'

      attr_reader :jobrnr_options
      attr_reader :argv

      def initialize(options, argv)
        @jobrnr_options = options.clone
        @argv = argv
      end

      def job(id, predecessor_ids = nil, &block)
        prefix = Jobrnr::DSL::Loader.instance.prefix

        predecessors = Array(predecessor_ids).map { |id| Jobrnr::Graph.instance[prefix_id(prefix, id)] }
        builder = Jobrnr::DSL::JobBuilder.new(
          id: prefix_id(prefix, id),
          predecessors: predecessors
        )
        job = Docile.dsl_eval(builder, &block).build
        Jobrnr::Plugins.instance.post_definition(job)
        Jobrnr::Graph.instance.add_job(job)
      end

      def import(prefix, filename)
        expanded_filename = Jobrnr::Util.expand_envars(filename)
        importer_relative = Jobrnr::Util.relative_to_file(expanded_filename, importer_filename)

        load_filename =
          if expanded_filename[0] != '/' && File.exist?(importer_relative)
            importer_relative
          else
            expanded_filename
          end

        Jobrnr::DSL::Loader.instance.evaluate(prefix, load_filename, jobrnr_options)
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
