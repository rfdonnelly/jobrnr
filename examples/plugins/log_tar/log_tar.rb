module JobRnr::Plugin
  class LogTar
    ARCHIVE_FILE = 'results.tar'

    def post_instance(message)
      relative_log = message.instance.log.sub("#{message.options.output_directory}/", '')
      command = "cd #{message.options.output_directory}; tar --append --file #{ARCHIVE_FILE} #{relative_log}"
      JobRnr::Log.debug command
      system command
    end

    def post_application(message)
      command = "cd #{message.options.output_directory}; gzip #{ARCHIVE_FILE}"
      JobRnr::Log.debug command
      system command
    end
  end
end
