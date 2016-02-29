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
    def parse(spec, argv)
      spec = process_spec(spec.clone)

      default_options = get_defaults(spec)

      options = parse_options(argv)

      if !Jobrnr::Util.array_subset_of?(options.keys, default_options.keys)
        common_options = options.keys & default_options.keys
        unsupported_options = options.keys - common_options
        unsupported_options_s = unsupported_options.map { |option| "+#{option}" }.join(', ')

        raise Jobrnr::ArgumentError, "The following options are not valid options: #{unsupported_options_s}\nValid options:\n#{help(spec)}"
      end

      default_options.merge(options)
    end

    def help(spec)
      defaults = get_defaults(spec)
      spec.map do |k, v|
        "+#{k.to_s} - #{v[:doc]} Default: #{defaults[k]}"
      end.join("\n")
    end

    def get_defaults(spec)
      spec.each_with_object({}) do |(option_name, option_spec), default_options|
        default_options[option_name] = option_spec.key?(:default) ? option_spec[:default] : false
      end
    end

    def process_spec(spec)
      spec.each { |option_name, option_spec| process_option_spec(option_spec) }
    end

    def process_option_spec(option_spec)
      if !option_spec[:type]
        option_spec[:type] =
          if !option_spec[:default]
            TrueClass
          else
            option_spec[:default].class
          end
      end

      if !option_spec[:default]
        option_spec[:default] = false
      end
    end

    def parse_options(argv)
      argv.each_with_object({}) do |arg, args|
        if md = arg.match(/^\+(.*?)=(.*)/)
          args[transform_key(md.captures.first)] = md.captures.last
        elsif md = arg.match(/^\+(\w+)$/)
          args[transform_key(md.captures.first)] = true
        end
      end
    end

    def transform_key(key)
      key.tr('-', '_').to_sym
    end
  end
end
