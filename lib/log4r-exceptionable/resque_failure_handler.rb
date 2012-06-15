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
             
          data = payload.clone
          mdc.put("resque_worker", worker.to_s)
          mdc.put("resque_queue", queue.to_s)
          mdc.put("resque_class", data.delete('class').to_s)
          mdc.put("resque_args", data.delete('args').inspect.to_s)
          
          # add in any extra payload data, in case resque plugins have
          # added to it (e.g. resque-lifecycle)
          data.each do |k, v|
            mdc.put("resque_payload_#{k}", v.inspect.to_s)
          end

          payload_class = Resque.constantize(payload['class']) rescue nil
          if payload_class && payload_class.respond_to?(:logger) && payload_class.logger.instance_of?(Log4r::Logger)
            error_logger = payload_class.logger
          else
            error_logger = Log4rExceptionable::Configuration.resque_failure_logger
          end
          
          error_logger.error(exception)
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
