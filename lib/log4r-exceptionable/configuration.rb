module Log4rExceptionable
    
  # Configuration for the failure backends that log exceptions with log4r
  #
  class Configuration

    class << self
      # required - default loggers used if source logger not available
      attr_accessor :rack_failure_logger, :resque_failure_logger
      attr_accessor :use_source_logger
    end

    # default values
    self.use_source_logger = true

    def self.configure
      yield self

      if ! self.rack_failure_logger && ! self.resque_failure_logger
        raise "log4r-exceptionable requires a rack_failure_logger or resque_failure_logger"
      end

      if self.rack_failure_logger
        self.set_logger(:rack_failure_logger)
      end
      
      if self.resque_failure_logger
        self.set_logger(:resque_failure_logger)
      end
    end

    def self.set_logger(accessor)
      if ! self.send(accessor).instance_of?(Log4r::Logger)
        name = self.send(accessor).to_s
        self.send("#{accessor}=", Log4r::Logger[name] || Log4r::Logger.new(name))
      end
    end

  end
  
end
