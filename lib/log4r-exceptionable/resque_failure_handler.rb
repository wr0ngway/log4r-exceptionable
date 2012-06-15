require 'resque'

module Log4rExceptionable
    
  # A Resque Failure backend that logs exceptions with log4r
  #
  class ResqueFailureHandler < ::Resque::Failure::Base

    def save
      begin
        mdc = Log4r::MDC
        original_mdc = mdc.get_context
        
        begin
          message = "#{exception.class}: #{exception.message}"
          
          mdc.put('resque_exception', exception.class.name)
          trace = Array(exception.backtrace)
          if trace.size > 0
            message << "\n"
            message << trace.join("\n")
            
            file, line = trace[0].split(":")
            mdc.put('resque_exception_file', file)
            mdc.put('resque_exception_line', line)
          end
          
          mdc.put("resque_worker", worker.to_s)
          mdc.put("resque_queue", queue.to_s)
          mdc.put("resque_class", payload['class'].to_s)
          mdc.put("resque_args", payload['args'].inspect.to_s)

          payload_class = Resque.constantize(payload['class']) rescue nil
          if payload_class && payload_class.respond_to?(:logger) && payload_class.logger.instance_of?(Log4r::Logger)
            error_logger = payload_class.logger
          else
            error_logger = Log4rExceptionable::Configuration.resque_failure_logger
          end
          
          error_logger.error(message)
        ensure
          # Since this is somewhat of a global map, clean the keys
          # we put in so other log messages don't see them
          mdc.get_context.keys.each do |k|
            mdc.remove(k) unless original_mdc.has_key?(k)
          end
        end
        
      rescue Exception => e
        puts "Log4r Exceptionable could not log resque exception: " + e.message
      end
    end

    def self.count
      # We can't get the total # of errors from graylog so we fake it
      # by asking Resque how many errors it has seen.
      ::Resque::Stat[:failed]
    end

  end
    
end
