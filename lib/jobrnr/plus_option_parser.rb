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
      attr_reader :doc
      attr_reader :value

      def initialize(id, name, default, doc)
        @name = name
        @id = id
        @default = default
        @doc = doc
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

    class FixnumOption < Option
      def parse_value(value)
        raise Jobrnr::ArgumentError, "No argument given for " \
          "'+#{name}' option" if value == :noarg

        begin
          Integer(value)
        rescue StandardError => e
          raise Jobrnr::ArgumentError, "Could not parse '#{value}' as " \
            "Integer type for the '+#{name}' option"
        end
      end
    end

    def self.parse(specs, plus_option_strings, help_info = nil)
      self.new.parse(specs, plus_option_strings)
    end

    def parse(specs, plus_option_strings, help_info = nil)
      option_definitions = transform_specs(specs.clone)
      plus_options = plus_options_to_hash(plus_option_strings)

      raise Jobrnr::HelpException, help(option_definitions, help_info) if plus_options.keys.include?(:help)

      unless Jobrnr::Util.array_subset_of?(plus_options.keys, option_definitions.keys)
        raise Jobrnr::ArgumentError, "The following options are not valid options: #{unsupported_options(plus_options, option_definitions)}\n\n#{help(option_definitions)}"
      end

      plus_options.each { |option_name, option_value| option_definitions[option_name].value = option_value }

      Hash[option_definitions.map { |option_name, option_definition| [option_name, option_definition.value] }]
    end

    def unsupported_options(options, option_definitions)
      common_options = options.keys & option_definitions.keys

      (options.keys - common_options)
        .map { |option| "+#{sym_to_s(option)}" }.join(', ')
    end

    def help(option_definitions, help_info = nil)
      lines = []

      lines << [
        'NAME',
        "  #{help_info[:name]}",
      ] if help_info && help_info[:name]

      lines << [
        'SYNOPSIS',
        "  #{help_info[:synopsis]}",
      ] if help_info && help_info[:synopsis]

      lines << [
        'DESCRIPTION',
        "  #{help_info[:description]}",
      ] if help_info && help_info[:description]

      lines << [
        'OPTIONS',
        option_definitions.map { |option_name, option_definition| help_format_option(option_definition) }
      ]

      lines << [
        help_info[:extra]
      ] if help_info && help_info[:extra]

      lines.join("\n\n")
    end

    def help_format_option(option_definition)
      [
        "  +#{help_format_name(option_definition)}",
        "    #{option_definition.doc} Default: #{option_definition.default}"
      ].join("\n")
    end

    def help_format_name(option_definition)
      option_definition.name + (option_definition.is_a?(BooleanOption) ? '[=<value>]' : '=<value>')
    end

    def transform_specs(specs)
      Hash[specs.map { |id, spec| [id, transform_spec(id, spec)] }]
    end

    def transform_spec(id, spec)
      spec[:default] ||= false
      klass = spec[:default].class

      type =
        if klass == String
          StringOption
        elsif klass == Fixnum
          FixnumOption
        elsif klass == TrueClass
          BooleanOption
        elsif klass == FalseClass
          BooleanOption
        end

      raise Jobrnr::TypeError, "Could not infer type from default value of " \
        "'#{spec[:default]}' for option '#{sym_to_s(id)}'" if type.nil?

      type.new(id, sym_to_s(id), spec[:default], spec[:doc])
    end

    def plus_options_to_hash(plus_option_strings)
      plus_option_strings.each_with_object({}) do |plus_option_string, plus_options|
        if md = plus_option_string.match(/^\+(.*?)=(.*)/)
          plus_options[s_to_sym(md.captures.first)] = md.captures.last
        elsif md = plus_option_string.match(/^\+((\w|-)+)$/)
          plus_options[s_to_sym(md.captures.first)] = :noarg
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
