module JobRnr
  module DSL
    class Loader
      @@imports = []
      @@import = {}
      @@prefixes = []
      @@script_objs = []
      @@script_obj = nil

      def self.evaluate(prefix, valid_jobs, filename)
        filename = JobRnr::Util.expand_envars(filename)

        @@imports.push(@@import) if @@import
        @@prefixes.push(prefix) if prefix
        @@import = {filename: filename, prefix: prefix, valid_jobs: valid_jobs}
        @@script_objs.push(@@script_obj) if @@script_obj
        @@script_obj = JobRnr::Script.new.from_file(filename, JobRnr::DSL::Commands)
        @@script_obj = @@script_objs.pop if @@script_objs.size > 0
        @@import = @@imports.pop if @@imports.size > 0
        @@prefixes.pop

        @@script_obj
      end

      def self.valid_jobs
        @@import[:valid_jobs]
      end

      def self.filename
        @@import[:filename]
      end

      def self.script
        @@script_obj
      end

      def self.prefix
        @@prefixes.join("_")
      end
    end
  end
end
