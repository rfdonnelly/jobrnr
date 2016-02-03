module Jobrnr
  require 'singleton'

  module PluginMethodStubs
    PLUGIN_METHODS = [
      :post_definition,
      :pre_instance,
      :post_instance,
      :post_interval,
      :post_application
    ]

    PLUGIN_METHODS.each do |meth|
      define_method(meth) { |*args| }
    end
  end

  class Plugins
    include Singleton
    include Jobrnr::PluginMethodStubs

    def initialize
      @plugins = []
    end

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
          Jobrnr::Log.debug "Loading plugin: #{file}"
          require file
        end
      end

      @plugins = create_plugin_instances(classes_in_module(Jobrnr::Plugin))
    end

    # Dispatches plugin method calls to all plugin instances.
    PLUGIN_METHODS.each do |meth|
      define_method(meth) do |*args|
        @plugins.each { |plugin| plugin.send(meth, *args) }
      end
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

    # Internal: Creates instances of plugin classes.
    #
    # Include PluginMethodStubs in each plugin so that they only need to define
    # the events they are interested in.
    #
    # Examples
    #
    #   plugins = create_plugin_instances(classes)
    #
    # Returns array of plugin class instances
    def create_plugin_instances(classes)
      classes.map(&:new)
        .each { |o| o.class.send(:include, Jobrnr::PluginMethodStubs) }
    end
  end
end

module Jobrnr
  module Plugin; end
end
