# frozen_string_literal: true

module Jobrnr
  # Provides the entry point of the application
  class Application
    require "pathname"

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      begin
        run_with_exceptions
      rescue ::OptionParser::ParseError, Jobrnr::UsageError => e
        Jobrnr::Log.error [e.message, "See `jobrnr --help`"].join("\n\n")
      rescue Jobrnr::HelpException => e
        puts e.message
        exit 0
      rescue Jobrnr::Error => e
        Jobrnr::Log.error e.message
      end
    end

    def run_with_exceptions
      option_parser = Jobrnr::OptionParser.new(@argv)
      options = option_parser.parse(argv)
      Log.verbosity = options.verbosity
      filenames, plus_options = classify_arguments(argv)

      raise Jobrnr::UsageError, "missing filename argument" if filenames.nil? || filenames.empty?
      raise Jobrnr::UsageError, "unrecognized option(s): #{filenames[1..].join(' ')}" if filenames.size > 1

      filename = filenames.first
      raise Jobrnr::Error, "file does not exist: #{filename}" unless File.exist?(filename)

      # load plugins
      Jobrnr::Plugins.instance.load(options.plugin_paths)

      Jobrnr::DSL::Loader.instance.evaluate(nil, filename, options, plus_options)
      options.output_directory = expand_output_directory(options.output_directory, filename)

      if options.dot
        Jobrnr::Log.info Jobrnr::Graph.instance.to_dot
        exit
      end

      slots = Jobrnr::Job::Slots.new(
        size: options.max_jobs,
      )
      pool = Jobrnr::Job::Pool.new
      ui = Jobrnr::UI.new(
        pool: pool
      )
      Jobrnr::Job::Dispatch.new(
        options: options,
        graph: Jobrnr::Graph.instance,
        pool: pool,
        stats: Jobrnr::Stats.new,
        slots: slots,
        ui: ui,
      ).run
    end

    def classify_arguments(argv)
      hash = argv.group_by do |arg|
        if arg[0] == "+"
          :plus_options
        else
          :filenames
        end
      end

      %i[filenames plus_options].map { |key| Array(hash[key]) }
    end

    def expand_output_directory(output_directory, user_script_filename)
      expanded_directory = Jobrnr::Util.expand_envars(output_directory)
      if Pathname.new(expanded_directory).absolute?
        expanded_directory
      else
        Jobrnr::Util.relative_to_file(expanded_directory, user_script_filename)
      end
    end
  end
end
