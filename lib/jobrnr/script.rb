module Jobrnr
  # Wraps a Ruby script in a Ruby class so that multiple scripts can be
  # loaded without namespace conflicts
  class Script
    # param code [String] ruby code to evaluate
    # param opts [Hash]
    def self.eval(code, opts = {})
      filename = opts[:filename]
      base_class = opts[:base_class]
      init_args = opts[:init_args] || []

      class_obj = Class.new(base_class)
      obj = class_obj.new(*init_args)

      begin
        obj.instance_eval(code, filename)
      rescue ::SyntaxError => e
        raise Jobrnr::SyntaxError.new(e)
      end

      obj
    end

    # param filename [String] filename to load
    # param opts [Hash]
    def self.load(filename, opts = {})
      opts[:filename] = filename

      code = IO.read(filename)
      self.eval(code, opts)
    end
  end
end
