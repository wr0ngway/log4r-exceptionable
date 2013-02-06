module Log4rExceptionable
    
  # Configuration for the failure backends that log exceptions with log4r
  #
  class Configuration

    class << self
      # required - default loggers used if source logger not available
      attr_accessor :rack_failure_logger, :resque_failure_logger, :sidekiq_failure_logger
      # Allows one to force use of default loggers by setting to false
      attr_accessor :use_source_logger
      # The level to log exceptions
      attr_accessor :log_level
      # whitelist of context keys (e.g. keys in rack env) to include in log4r context when logging
      attr_accessor :context_inclusions
      # blacklist of context keys (e.g. keys in rack env) to exclude in log4r context when logging
      attr_accessor :context_exclusions
      # Swallow exceptions raised by the call to the logger, printing to stderr, defaults to true
      attr_accessor :failsafe_logging
    end

    # default values
    self.use_source_logger = true
    self.log_level = :fatal
    self.failsafe_logging = true

    def self.configure
      yield self

      if ! self.rack_failure_logger && ! self.resque_failure_logger && ! self.sidekiq_failure_logger
        raise "log4r-exceptionable requires a rack_failure_logger or resque_failure_logger or sidekiq_failure_logger"
      end

      if self.rack_failure_logger
        self.set_logger(:rack_failure_logger)
      end
      
      if self.resque_failure_logger
        self.set_logger(:resque_failure_logger)
      end
      
      if self.sidekiq_failure_logger
        self.set_logger(:sidekiq_failure_logger)
      end
      
      self.context_inclusions = Set.new(self.context_inclusions) if self.context_inclusions
      self.context_exclusions = Set.new(self.context_exclusions) if self.context_exclusions

      raise "Invalid log level: #{self.log_level}" unless Log4r::LNAMES.include?(self.log_level.to_s.upcase)
      self.log_level = self.log_level.to_sym
    end

    def self.set_logger(accessor)
      if ! self.send(accessor).instance_of?(Log4r::Logger)
        name = self.send(accessor).to_s
        self.send("#{accessor}=", Log4r::Logger[name] || Log4r::Logger.new(name))
      end
    end
    
  end
  
end
