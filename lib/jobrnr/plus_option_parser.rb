# frozen_string_literal: true

module Jobrnr
  # Parses plusargs
  #
  # Specifying options:
  #
  # * Option type is inferred by the options default value.
  # * Absence of default value infers a default of false.
  #
  # Options on the command line:
  #
  # * Options are in the form of `+<name>=<value>`
  # * Absence of `=<value>' infers true for Boolean options
  #
  # Examples of plusargs:
  #
  # * `+string_option=string`
  # * `+integer_option=5`
  # * `+boolean_option`
  class PlusOptionParser
    # PlusOption base class
    class PlusOption
      attr_reader :id
      attr_reader :name
      attr_reader :default
      attr_reader :description
      attr_reader :value

      def initialize(id, name, default, description)
        @name = name
        @id = id
        @default = default
        @description = description
        @value = default
      end

      def value=(value)
        @value = parse_value(value)
      end

      def parse_value(value); end
    end

    # An option that accepts true/false values
    class BooleanOption < PlusOption
      def parse_value(value)
        case value
        when :noarg
          true
        when /^(true|t|yes|y|1)$/ # rubocop: disable Lint/DuplicateBranch
          true
        when /^(false|f|no|n|0)$/
          false
        else
          raise Jobrnr::ArgumentError,
            "Could not parse '#{value}' as Boolean " \
            "type for the '+#{name}' option"
        end
      end
    end

    # An option that accepts string values
    class StringOption < PlusOption
      def parse_value(value)
        if value == :noarg
          raise Jobrnr::ArgumentError,
            "No argument given for '+#{name}' option"
        end

        value
      end
    end

    # An option that accepts Integer values
    class IntegerOption < PlusOption
      def parse_value(value)
        if value == :noarg
          raise Jobrnr::ArgumentError,
            "No argument given for '+#{name}' option"
        end

        begin
          Integer(value)
        rescue StandardError
          raise Jobrnr::ArgumentError, "Could not parse '#{value}' as " \
            "Integer type for the '+#{name}' option"
        end
      end
    end

    VALUE_OPTION_TYPE_MAP = {
      String => StringOption,
      TrueClass => BooleanOption,
      FalseClass => BooleanOption,
      Integer => IntegerOption,
    }.freeze

    def self.parse(help_spec, plus_options)
      new.parse(help_spec, plus_options)
    end

    # Parses an array of plus options (+key=value pairs) given an option
    # specification.
    #
    # The presence `+help` option prints help to standard output.
    #
    # The help_spec argument takes a) an options specification Hash directly or
    # b) a help specification with an :options key containing the options
    # specification.
    #
    # The help specification accepts the following keys:
    #
    # * :name - The name of .jr file
    # * :synopsis - The form of command to run the .jr file
    # * :description - A multi-line description of the .jr file
    # * :options - The options specification Hash
    # * :extra - Extra lines to append to the +help output
    #
    # The options (plural) specification is a Hash where the keys are name of the
    # options and the values are option specification Hashes.
    #
    # Each option (singular) specification Hash accepts the following keys:
    #
    # * :default - The default value of the option.  If omitted, the default
    #   value is inferred as `false`.  The option data type is inferred from
    #   the default value.  Supported types are Integer, Boolean, and String.
    # * :doc|:desciption - A description of the option.  Displayed when `+help`
    #   plus option is present.
    #
    # Examples:
    #
    # Help specification input
    #
    # ```ruby
    # parse({
    #   name: 'example',
    #   synopsys: 'jobrnr example.jr',
    #   description: 'example description',
    #   options: {
    #     default_true: {
    #       default: true,
    #       description: 'An option with a default true value.',
    #     },
    #     default_inferred: {
    #       description: 'An option with a default inferred faluse value.',
    #     },
    #     fix_num: {
    #       default: 1,
    #       description: 'An Integer option.',
    #     },
    #     string: {
    #       default: 'hello world',
    #       doc: 'A string option.',
    #     },
    #   },
    #   extra: <<~EOF
    #     EXAMPLES
    #
    #       jobrnr example.jr +default-inferred +default-true=false
    #
    #       jobrnr example.jr +string='test'
    #   EOF
    # }, %w[+fix-num=5 +string=test])
    # ```
    #
    # Option specification input only
    #
    # ```ruby
    # parse({
    #   some_option: {
    #     description: 'An option.'
    #   }
    # }, %w[+some-option])
    # ```
    #
    # Returns Hash of options.
    def parse(help_spec, plus_options)
      if help_spec.key?(:options)
        options_spec = help_spec[:options]
        doc_params = help_spec
      else
        options_spec = help_spec
        doc_params = {}
      end

      option_definitions = specs_to_defs(options_spec)
      plus_options_hash = plus_options_to_hash(plus_options)

      raise Jobrnr::HelpException, help(option_definitions, doc_params) if plus_options_hash.keys.include?(:help)

      unless Jobrnr::Util.array_subset_of?(plus_options_hash.keys, option_definitions.keys)
        raise Jobrnr::ArgumentError,
          format(
            "The following options are not valid options: %<invalid_options>s\n\n%<help>s",
            invalid_options: unsupported_options(plus_options_hash, option_definitions),
            help: help(option_definitions)
          )
      end

      plus_options_hash.each { |option_name, option_value| option_definitions[option_name].value = option_value }

      option_definitions.transform_values(&:value)
    end

    def unsupported_options(options, option_definitions)
      common_options = options.keys & option_definitions.keys

      (options.keys - common_options)
        .map { |option| "+#{sym_to_s(option)}" }.join(", ")
    end

    def help(option_definitions, doc_params = {})
      lines = []

      if doc_params[:name]
        lines << [
          "NAME",
          "  #{doc_params[:name]}",
        ]
      end

      if doc_params[:synopsis]
        lines << [
          "SYNOPSIS",
          "  #{doc_params[:synopsis]}",
        ]
      end

      if doc_params[:description]
        lines << [
          "DESCRIPTION",
          doc_params[:description].split("\n").map { |line| "  #{line}" }.join("\n"),
        ]
      end

      lines << [
        "OPTIONS",
        option_definitions.values.map { |option_definition| help_format_option(option_definition) },
        "  +help\n    Show this help and exit."
      ]

      if doc_params[:extra]
        lines << [
          doc_params[:extra]
        ]
      end

      lines.join("\n\n")
    end

    def help_format_option(option_definition)
      [
        "  +#{help_format_name(option_definition)}",
        "    #{option_definition.description} Default: #{option_definition.default}"
      ].join("\n")
    end

    def help_format_name(option_definition)
      option_definition.name + (option_definition.is_a?(BooleanOption) ? "[=<value>]" : "=<value>")
    end

    def specs_to_defs(options_spec)
      options_spec
        .map { |id, spec| [id, spec_to_def(id, spec)] }
        .to_h
    end

    def spec_to_def(id, spec)
      spec[:default] ||= false

      value_type = VALUE_OPTION_TYPE_MAP.keys.find { |value_type| spec[:default].is_a?(value_type) }
      if value_type.nil?
        raise Jobrnr::TypeError, "Could not infer type from default value of " \
          "'#{spec[:default]}' for option '#{sym_to_s(id)}'"
      end

      option_type = VALUE_OPTION_TYPE_MAP[value_type]
      option_type.new(
        id,
        sym_to_s(id),
        spec[:default],
        spec[:doc] || spec[:description]
      )
    end

    def plus_options_to_hash(plus_options)
      plus_options.each_with_object({}) do |plus_option, plus_options_hash|
        if (md = plus_option.match(/^\+(.*?)=(.*)/))
          plus_options_hash[s_to_sym(md.captures.first)] = md.captures.last
        elsif (md = plus_option.match(/^\+((\w|-)+)$/))
          plus_options_hash[s_to_sym(md.captures.first)] = :noarg
        end
      end
    end

    def s_to_sym(s)
      s.tr("-", "_").to_sym
    end

    def sym_to_s(sym)
      sym.to_s.tr("_", "-")
    end
  end
end
