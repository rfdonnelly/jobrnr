# frozen_string_literal: true

module Jobrnr
  module DSL
    # Defines the top-level DSL commands: job and import
    class Commands
      require 'docile'

      attr_reader :jobrnr_options
      attr_reader :plus_options

      def initialize(options, plus_options)
        @jobrnr_options = options.clone
        @plus_options = plus_options
      end

      def job(id, predecessor_ids = nil, &block)
        raise Jobrnr::ArgumentError, Jobrnr::Util.strip_heredoc(<<-EOF) unless block_given?
          job ':#{id}' definition is incomplete @ #{caller_source}

            Example:

              job :#{id}[, ...] do
                ...
              end
        EOF

        prefix = Jobrnr::DSL::Loader.instance.prefix

        pids = Array(predecessor_ids).map { |pid| prefix_id(prefix, pid) }
        pids_not_found =
          pids
          .map { |pid| [pid, graph.id?(pid)] }
          .select { |_, exists| exists == false }
          .map { |pid, _| "':#{pid}'" }

        unless pids_not_found.empty?
          raise Jobrnr::ArgumentError,
            "job ':#{id}' references undefined predecessor job(s) " \
            "#{pids_not_found.join(', ')} @ #{caller_source}"
        end

        predecessors = pids.map { |pid| graph[pid] }
        builder = Jobrnr::DSL::JobBuilder.new(
          id: prefix_id(prefix, id),
          predecessors: predecessors
        )
        job = Docile.dsl_eval(builder, &block).build
        Jobrnr::Plugins.instance.post_definition(job)
        graph.add_job(job)
      end

      def import(prefix, filename, *plus_options)
        unless prefix.is_a?(String) && !prefix.strip.empty?
          raise Jobrnr::ArgumentError,
            "import prefix argument must be a non-blank string " \
            "@ #{caller_source}"
        end

        expanded_filename = Jobrnr::Util.expand_envars(filename)
        importer_relative = Jobrnr::Util.relative_to_file(expanded_filename, importer_filename)

        load_filename =
          if expanded_filename[0] != '/' && File.exist?(importer_relative)
            importer_relative
          else
            expanded_filename
          end

        unless File.exist?(load_filename)
          raise Jobrnr::ArgumentError,
            "file '#{filename}' not found " \
            "@ #{caller_source}"
        end

        Jobrnr::DSL::Loader.instance.evaluate(prefix, load_filename, jobrnr_options, plus_options)
      end

      def prefix_id(prefix, id)
        if prefix.length.positive?
          "#{prefix}_#{id}".to_sym
        else
          id
        end
      end

      def importer_filename
        caller(2)[0].split(/:/).first
      end

      def caller_source
        Jobrnr::Util.caller_source(1)
      end

      def graph
        Jobrnr::Graph.instance
      end
    end
  end
end
