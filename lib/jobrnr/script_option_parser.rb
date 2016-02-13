module Jobrnr
  class ScriptOptionParser
    def parse(argv)
      argv.each_with_object({}) do |arg, args|
        if md = arg.match(/^\+(.*?)=(.*)/)
          args[transform_key(md.captures.first)] = md.captures.last
        elsif md = arg.match(/^\+(\w+)$/)
          args[transform_key(md.captures.first)] = true
        end
      end
    end

    def transform_key(key)
      key.gsub(/-/, '_').to_sym
    end
  end
end
