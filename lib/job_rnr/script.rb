module JobRnr
  # Wraps a Ruby script in a Ruby class so that multiple scripts can be
  # loaded without namespace conflicts
  class Script
    # Converts a filename (w/o extension) to a Ruby class name
    def classify(name)
      name.split("_").map(&:capitalize).join
    end

    def from_string(classname, code_string, filename = nil, base_class = nil)
      class_obj = Object.const_set(classname, Class.new(base_class))
      obj = class_obj.new
      obj.instance_eval(code_string, filename)

      obj
    end

    def from_file(filename, base_class = nil)
      basename = File.basename(filename, '.avj')
      classname = classify(basename)

      code_string = IO.read(filename)
      from_string(classname, code_string, filename, base_class)
    end
  end
end
