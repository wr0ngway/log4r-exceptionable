require 'resque'

module Log4rExceptionable
    
  # A Resque Failure backend that logs exceptions with log4r
  #
  class ResqueFailureHandler < ::Resque::Failure::Base
    include Log4rExceptionable::Helper
    
    def save
      
      log_with_context do |context|
        
        data = payload.clone
        payload_class_name = data.delete('class')
        payload_class = Resque.constantize(payload_class_name) rescue payload_class_name
        
        add_context(context, "resque_worker", worker)
        add_context(context, "resque_queue", queue)
        add_context(context, "resque_class", payload_class)
        add_context(context, "resque_args", data.delete('args'))
        
        # add in any extra payload data, in case resque plugins have
        # added to it (e.g. resque-lifecycle)
        data.each do |k, v|
          add_context(context, "resque_payload_#{k}", v)
        end

        error_logger = nil
        if Log4rExceptionable::Configuration.use_source_logger
          payload_class = Resque.constantize(payload['class']) rescue nil
          if payload_class && payload_class.respond_to?(:logger) && payload_class.logger.instance_of?(Log4r::Logger)
            error_logger = payload_class.logger
          end
        end
        
        error_logger ||= Log4rExceptionable::Configuration.resque_failure_logger
        
        error_logger.error(exception)
      end
      
    end

    def self.count
      # We can't get the total # of errors from graylog so we fake it
      # by asking Resque how many errors it has seen.
      ::Resque::Stat[:failed]
    end

  end
    
end
