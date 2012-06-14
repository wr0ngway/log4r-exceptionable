module Log4rExceptionable
    
  # Failure backends that log exceptions with log4r
  #
  # Log4rExceptionable::Configuration.configure do |config|
  #   # required
  #   config.resque_failure_logger = "rails::SomeLogger"
  #   config.rack_failure_logger = "rails::SomeLogger"
  # end
  #
  # Rails.application.config.middleware.use "Log4rExceptionable::RackFailureHandler"
  # Resque::Failure.backend = Log4rExceptionable::ResqueFailureHandler
  #
  class Configuration

    class << self
      # required
      attr_accessor :rack_failure_logger, :resque_failure_logger
    end

    def self.configure
      yield self
      raise "log4r-exceptionable requires a rack_failure_logger or resque_failure_logger" unless self.rack_failure_logger || self.resque_failure_logger

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
