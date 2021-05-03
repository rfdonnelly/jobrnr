# frozen_string_literal: true

module Jobrnr
  module DSL
    require 'singleton'

    # Manages stack of scripts (nested imports)
    class Loader
      include Singleton

      def initialize
        @imports = []
        @import = {}
        @prefixes = []
        @script_objs = []
        @script_obj = nil
      end

      def evaluate(prefix, filename, *init_args)
        @imports.push(@import) if @import
        @prefixes.push(prefix) if prefix
        @import = { filename: filename, prefix: prefix }
        @script_objs.push(@script_obj) if @script_obj
        @script_obj = Jobrnr::Script.load(filename, { init_args: init_args, base_class: Jobrnr::DSL::Commands })
        @script_obj = @script_objs.pop if @script_objs.size.positive?
        @import = @imports.pop if @imports.size.positive?
        @prefixes.pop

        @script_obj
      end

      def filename
        @import[:filename]
      end

      def script
        @script_obj
      end

      def prefix
        @prefixes.join('_')
      end
    end
  end
end
