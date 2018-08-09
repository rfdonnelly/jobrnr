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
    class Option
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

      def parse_value(value)
      end
    end

    class BooleanOption < Option
      def parse_value(value)
        if value == :noarg
          true
        elsif value.match(/^(true|t|yes|y|1)$/)
          true
        elsif value.match(/^(false|f|no|n|0)$/)
          false
        else
          raise Jobrnr::ArgumentError, "Could not parse '#{value}' as Boolean " \
            "type for the '+#{name}' option"
        end
      end
    end

    class StringOption < Option
      def parse_value(value)
        raise Jobrnr::ArgumentError, "No argument given for " \
          "'+#{name}' option" if value == :noarg

        value
      end
    end

    class IntegerOption < Option
      def parse_value(value)
        raise Jobrnr::ArgumentError, "No argument given for " \
          "'+#{name}' option" if value == :noarg

        begin
          Integer(value)
        rescue StandardError
          raise Jobrnr::ArgumentError, "Could not parse '#{value}' as " \
            "Integer type for the '+#{name}' option"
        end
      end
    end

    def self.parse(help_spec, plus_options)
      self.new.parse(help_spec, plus_options)
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
    # }, %w(+fix-num=5 +string=test))
    # ```
    #
    # Option specification input only
    #
    # ```ruby
    # parse({
    #   some_option: {
    #     description: 'An option.'
    #   }
    # }, %w(+some-option))
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
        raise Jobrnr::ArgumentError, "The following options are not valid options: #{unsupported_options(plus_options_hash, option_definitions)}\n\n#{help(option_definitions)}"
      end

      plus_options_hash.each { |option_name, option_value| option_definitions[option_name].value = option_value }

      Hash[option_definitions.map { |option_name, option_definition| [option_name, option_definition.value] }]
    end

    def unsupported_options(options, option_definitions)
      common_options = options.keys & option_definitions.keys

      (options.keys - common_options)
        .map { |option| "+#{sym_to_s(option)}" }.join(', ')
    end

    def help(option_definitions, doc_params = {})
      lines = []

      lines << [
        'NAME',
        "  #{doc_params[:name]}",
      ] if doc_params[:name]

      lines << [
        'SYNOPSIS',
        "  #{doc_params[:synopsis]}",
      ] if doc_params[:synopsis]

      lines << [
        'DESCRIPTION',
        doc_params[:description].split("\n").map { |line| "  #{line}" }.join("\n"),
      ] if doc_params[:description]

      lines << [
        'OPTIONS',
        option_definitions.values.map { |option_definition| help_format_option(option_definition) },
        "  +help\n    Show this help and exit."
      ]

      lines << [
        doc_params[:extra]
      ] if doc_params[:extra]

      lines.join("\n\n")
    end

    def help_format_option(option_definition)
      [
        "  +#{help_format_name(option_definition)}",
        "    #{option_definition.description} Default: #{option_definition.default}"
      ].join("\n")
    end

    def help_format_name(option_definition)
      option_definition.name + (option_definition.is_a?(BooleanOption) ? '[=<value>]' : '=<value>')
    end

    def specs_to_defs(options_spec)
      Hash[options_spec.map { |id, spec| [id, spec_to_def(id, spec)] }]
    end

    def spec_to_def(id, spec)
      spec[:default] ||= false
      klass = spec[:default].class

      type =
        if klass == String
          StringOption
        elsif klass == TrueClass
          BooleanOption
        elsif klass == FalseClass
          BooleanOption
        elsif spec[:default].is_a? Integer
          IntegerOption
        end

      raise Jobrnr::TypeError, "Could not infer type from default value of " \
        "'#{spec[:default]}' for option '#{sym_to_s(id)}'" if type.nil?

      type.new(id, sym_to_s(id), spec[:default], spec[:doc] || spec[:description])
    end

    def plus_options_to_hash(plus_options)
      plus_options.each_with_object({}) do |plus_option, plus_options_hash|
        if md = plus_option.match(/^\+(.*?)=(.*)/)
          plus_options_hash[s_to_sym(md.captures.first)] = md.captures.last
        elsif md = plus_option.match(/^\+((\w|-)+)$/)
          plus_options_hash[s_to_sym(md.captures.first)] = :noarg
        end
      end
    end

    def s_to_sym(s)
      s.tr('-', '_').to_sym
    end

    def sym_to_s(sym)
      sym.to_s.tr('_', '-')
    end
  end
end
