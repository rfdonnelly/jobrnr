# frozen_string_literal: true

module Jobrnr
  module Plugin
    # The LogTar plugin appends job logs to an tar archive as jobs complete.
    # When all jobs complete, the tar archive is then gzipped.
    class LogTar
      ARCHIVE_FILE = "results.tar"

      def post_instance(message)
        relative_log = message.instance.log.sub("#{message.options.output_directory}/", "")
        command = "cd #{message.options.output_directory}; tar --append --file #{ARCHIVE_FILE} #{relative_log}"
        Jobrnr::Log.debug command
        system command
      end

      def post_application(message)
        command = "cd #{message.options.output_directory}; gzip #{ARCHIVE_FILE}"
        Jobrnr::Log.debug command
        system command
      end
    end
  end
end
