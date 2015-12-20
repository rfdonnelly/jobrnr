module JobRnr
  require 'singleton'

  class Plugins
    include Singleton

    # Public: Load plugins from path(s).
    #
    # paths - Path String or Array of path Strings to search for *.rb files.
    #
    # Examples
    #
    #   load('/example/path')
    #
    #   load(('/example/path/0', '/example/path/1'])
    #
    # Returns nothing.
    # Raises LoadError [see Kernel::require]
    def load(paths)
      Array(paths).each do |path|
        Dir.glob(File.join(path, '*.rb')) do |file|
          # FIXME: require raises LoadError if it cannot find file.
          # Here we are only calling require on files we have found.
          # What about insufficient permissions?
          # What about syntax error?
          JobRnr::Log.debug "Loading plugin: #{file}"
          require file
        end
      end
    end

    # Public: Returns all JobType plugins
    #
    # Returns Array of JobType plugins
    def job_types
      @job_types ||= classes_in_module(JobRnr::JobType)
    end

    # Internal: Returns all Classes defined in a given Module.
    #
    # mod - Module to return Classes for.
    #
    # Examples
    #
    #   classes = classes_in_module(MyModule)
    #
    # Returns Array of all Classes defined in Module mod
    def classes_in_module(mod)
      mod.constants
        .select { |c| Class === mod.const_get(c) }
        .map { |c| mod.const_get(c) }
    end
  end
end

module JobRnr
  module JobType; end
end
