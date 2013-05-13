begin
  require "oj"
rescue LoadError
  require "json"
end

module LogjamAgent
  class Request
    attr_reader :fields

    def initialize(app, env, logger, initial_fields)
      @logger = logger
      @app = app
      @env = env
      @forwarder = Forwarders.get(app, env)
      @lines = []
      @id = UUID4R::uuid(1).gsub('-','')
      @fields = initial_fields.merge(:request_id => @id, :host => LogjamAgent.hostname, :process_id => Process.pid, :lines => @lines)
      @mutex = Mutex.new
    end

    def id
      "#{@app}-#{@env}-#{@id}"
    end

    def action
      @fields[:action]
    end

    def caller_id
      @fields[:caller_id]
    end

    def caller_action
      @fields[:caller_action]
    end

    def add_line(severity, timestamp, message)
      @mutex.synchronize do
        @lines << [severity, format_time(timestamp), message.strip]
      end
    end

    def add_exception(exception)
      @mutex.synchronize do
        ((@fields[:exceptions] ||= []) << exception).uniq!
      end
    end

    def forward
      engine = @fields.delete(:engine)
      @forwarder.forward(LogjamAgent.encode_payload(@fields), :engine => engine)
    rescue Exception => e
      handle_forwarding_error(e)
    end

    private

    def format_time(t)
      # iso time with microseconds
      t.strftime("%Y-%m-%dT%H:%M:%S.#{"%06d" % t.usec}")
    end

    def handle_forwarding_error(exception)
      @logger.error exception.to_s
      LogjamAgent.error_handler.call(exception)
    rescue Exception
      # swallow all exceptions
    end

  end
end
