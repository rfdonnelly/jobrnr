module JobRnr
  module Util
    # expand environment variables in string
    # supports '${name}' and '$name' syntax
    # supports multiple environment variables in single string
    def self.expand_envars(path)
      path.gsub(/\$\{?(\w+)\}?/) { ENV[$1] }
    end

    # makes from_file relative to to_file location
    #
    # Example:
    #
    #     relative_to_file('path_a/file_a', 'path_b/file_b')
    #     => 'path_b/path_a/file_a'
    def self.relative_to_file(from_file, to_file)
      File.join(File.dirname(to_file), File.basename(from_file))
    end
  end
end
