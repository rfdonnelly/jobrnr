module JobRnr
  module DSL
    require 'singleton'

    class Loader
      include Singleton

      def initialize
        @imports = []
        @import = {}
        @prefixes = []
        @script_objs = []
        @script_obj = nil
      end

      def evaluate(prefix, valid_jobs, filename, *init_args)
        @imports.push(@import) if @import
        @prefixes.push(prefix) if prefix
        @import = { filename: filename, prefix: prefix, valid_jobs: valid_jobs }
        @script_objs.push(@script_obj) if @script_obj
        @script_obj = JobRnr::Script.load(filename, {init_args: init_args, base_class: JobRnr::DSL::Commands})
        @script_obj = @script_objs.pop if @script_objs.size > 0
        @import = @imports.pop if @imports.size > 0
        @prefixes.pop

        @script_obj
      end

      def valid_jobs
        @import[:valid_jobs]
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
