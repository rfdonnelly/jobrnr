module AV
  module Jobs
    module DSL
      class Loader
        @@imports = []
        @@import = {}
        @@prefixes = []

        def self.evaluate(prefix, valid_jobs, filename)
          @@imports.push(@@import) if @@import
          @@prefixes.push(prefix) if prefix
          @@import = {filename: filename, prefix: prefix, valid_jobs: valid_jobs}
          script_obj = AV::Jobs::Script.new.from_file(filename, AV::Jobs::DSL::Commands)
          @@import = @@imports.pop if @@imports.length > 0
          @@prefixes.pop

          script_obj
        end

        def self.valid_jobs
          @@import[:valid_jobs]
        end

        def self.filename
          @@import[:filename]
        end

        def self.prefix
          @@prefixes.join("_")
        end
      end
    end
  end
end
