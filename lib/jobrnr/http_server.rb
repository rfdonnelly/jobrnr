module Jobrnr
  require 'socket'

  class HttpServer
    attr_reader :server
    attr_reader :slots

    def initialize(slots)
      @server = TCPServer.new("localhost", 0)
      @slots = slots
    end

    def start
      $stdout.puts "Change the value of max-jobs with http://localhost:#{server.addr[1]}/max-jobs/N"
      Thread.new do
        loop do
          socket = server.accept
          request = socket.readpartial(2048)
          _, path, _ = request.lines.first.split(" ")
          k, v, *extra = path.split("/")[1..]
          if extra.size > 0
            respond(socket, 404, usage("Invalid URL"))
          elsif k == "max-jobs"
            if v.nil?
              respond(socket, 200, "The number of simulatenous jobs")
            else
              begin
                v = Integer(v)
                slots.resize(v)
                respond(socket, 200, "max-jobs changed to #{v}")
              rescue ::ArgumentError => e
                respond(socket, 400, usage(e.message))
              end
            end
          else
            respond(socket, 404, usage("Invalid URL"))
          end
        end
      end
    end

    def usage(message)
      <<~EOF
        #{message}

        Available resources:

        * /max-jobs/N -- The number of simulatenous jobs
      EOF
    end

    def respond(socket, code, data = "")
      data << "\n" if data[-1] != "\n"

      socket.write <<~EOF
        HTTP/1.1 #{code}
        Content-Length: #{data.size}

        #{data}
      EOF
    end
  end
end
