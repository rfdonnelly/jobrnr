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
  class ScriptOptionParser
    def self.parse(specs, argv)
      full_specs = process_specs(specs.clone)
      default_options = get_defaults(full_specs)

      options = parse_options(argv)

      unless Jobrnr::Util.array_subset_of?(options.keys, default_options.keys)
        raise Jobrnr::ArgumentError, "The following options are not valid options: #{unsupported_options(options, default_options)}\n\n#{help(full_specs)}"
      end

      typed_options = type_cast_options(options, full_specs)

      default_options.merge(typed_options)
    end

    def self.unsupported_options(options, default_options)
      common_options = options.keys & default_options.keys

      (options.keys - common_options)
        .map { |option| "+#{option}" }.join(', ')
    end

    def self.help(specs)
      defaults = get_defaults(specs)

      [
        'OPTIONS',
        specs.map { |option, spec| help_format_option(option, spec, defaults[option]) }
      ].join("\n\n")
    end

    def self.help_format_option(option, spec, default)
      [
        "  +#{help_format_name(option, spec)}",
        "    #{spec[:doc]} Default: #{default}"
      ].join("\n")
    end

    def self.help_format_name(option, spec)
      sym_to_s(option) + ((spec[:type] == TrueClass) ? '' : '=<value>')
    end

    def self.get_defaults(specs)
      specs.each_with_object({}) do |(option, spec), default_options|
        default_options[option] = spec.key?(:default) ? spec[:default] : false
      end
    end

    def self.process_specs(specs)
      specs.each { |option, spec| process_spec(spec) }
    end

    def self.process_spec(spec)
      if !spec[:type]
        spec[:type] =
          if !spec[:default]
            FalseClass
          else
            spec[:default].class
          end
      end

      if !spec[:default]
        spec[:default] = false
      end
    end

    def self.parse_options(argv)
      argv.each_with_object({}) do |arg, args|
        if md = arg.match(/^\+(.*?)=(.*)/)
          args[s_to_sym(md.captures.first)] = md.captures.last
        elsif md = arg.match(/^\+((\w|-)+)$/)
          args[s_to_sym(md.captures.first)] = :noarg
        end
      end
    end

    def self.type_cast_options(options, specs)
      options.keys.each_with_object({}) do |option, typed_options|
        typed_options[option] = type_cast_option(option, options[option], specs[option])
      end
    end

    def self.type_cast_option(option, value, spec)
      if spec[:type] == TrueClass || spec[:type] == FalseClass
        if value == :noarg
          true
        elsif value.match(/^(true|t|yes|y|1)$/)
          true
        elsif value.match(/^(false|f|no|n|0)$/)
          false
        else
          raise Jobrnr::ArgumentError, "Could not parse '#{value}' as Boolean type for the '+#{sym_to_s(option)} option"
        end
      elsif value == :noarg
        raise Jobrnr::ArgumentError, "No argument given for '+#{sym_to_s(option)}' option"
      elsif spec[:type] == Fixnum
        Integer(value) # TODO catch exception and rethrow as Jobrnr::ArgumentError
      else
        value
      end
    end

    def self.s_to_sym(s)
      s.tr('-', '_').to_sym
    end

    def self.sym_to_s(sym)
      sym.to_s.tr('_', '-')
    end
  end
end
