module JobRnr
  # Wraps a Ruby script in a Ruby class so that multiple scripts can be
  # loaded without namespace conflicts
  class Script
    def from_string(code_string, filename = nil, base_class = nil)
      class_obj = Class.new(base_class)
      obj = class_obj.new
      obj.instance_eval(code_string, filename)

      obj
    end

    def from_file(filename, base_class = nil)
      code_string = IO.read(filename)
      from_string(code_string, filename, base_class)
    end
  end
end
