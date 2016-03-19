module Jobrnr
  module Util
    # Expand environment variables in string.
    #
    # * Supports '${name}' and '$name' syntax
    # * Supports multiple environment variables in single string
    def self.expand_envars(path)
      path.gsub(/\$\{?(\w+)\}?/) { ENV[Regexp.last_match.captures.first] }
    end

    # Makes from_file relative to to_file location.
    #
    # Example:
    #
    #     relative_to_file('path_a/file_a', 'path_b/file_b')
    #     => '$PWD/path_b/path_a/file_a'
    def self.relative_to_file(from_file, to_file)
      File.expand_path(File.join(File.dirname(to_file), from_file))
    end

    # Determines if Array a is a subset of Array b.  Order doesn't matter.
    def self.array_subset_of?(a, b)
      (a & b) == a
    end

    # Returns the filename and line number of the caller of the caller.
    #
    # Example:
    #
    #   def f0; f1; end
    #   def f1; caller_source; end
    #
    #   caller_source will return the file ane line number of the 'f1;'
    #   statement.
    def self.caller_source(additional_levels = 0)
      caller[2 + additional_levels].split(/:/)[0..1].join(':')
    end

    # Strips indentation in heredocs.
    #
    # Would use Ruby 2.3 '~' heredocs instead but Cygwin does not yet have Ruby
    # 2.3.
    #
    # See strip_heredoc in Rails.
    def self.strip_heredoc(s)
      indent = s.scan(/^[ \t]*(?=\S)/).min.size || 0
      s.gsub(/^[ \t]{#{indent}}/, '')
    end
  end
end
