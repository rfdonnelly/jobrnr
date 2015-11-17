module AV
  module Util
    # expand environment variables in string
    # supports '${name}' and '$name' syntax
    # supports multiple environment variables in single string
    def self.expand_envars(path)
      path.gsub(/\$\{?(\w+)\}?/) {ENV[$1]}
    end
  end
end
