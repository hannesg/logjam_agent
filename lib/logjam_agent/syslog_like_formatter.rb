require 'socket'
require 'logger'

module LogjamAgent
  class SyslogLikeFormatter
    def initialize
      @hostname = Socket.gethostname.split('.').first
      @app_name = "rails"
    end

    attr_accessor :extra_attributes

    SEV_LABEL = Logger::SEV_LABEL.map{|sev| "%-5s" % sev}

    def format_severity(severity)
      SEV_LABEL[severity] || 'ALIEN'
    end

    def format_time(timestamp)
      timestamp.strftime("%b %d %H:%M:%S.#{timestamp.usec}")
    end

    def format_msg(msg)
      "#{msg}".sub(/^[\s\n]+/, '').sub(/[\s\n]+$/,"\n")
    end

    def call(severity, timestamp, progname, msg)
      "#{format_severity(severity)} #{format_time(timestamp)} #{progname||@app_name}[#{$$}]#{render_extra_attributes}: #{format_msg(msg)}"
    end

    def render_extra_attributes
      (self.extra_attributes||[]).map{|key, value| " #{key}[#{value}]"}
    end

    def add_extra_attributes(attributes)
      (self.extra_attributes ||= []).concat(attributes)
    end
  end
end
