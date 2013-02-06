require 'sidekiq'

module Log4rExceptionable
    
  # A Resque Failure backend that logs exceptions with log4r
  #
  class SidekiqFailureHandler
    include Log4rExceptionable::Helper
    
    def call(worker, msg, queue)
      begin
        yield
      rescue => ex
        log_exception(worker, queue, ex, msg)
        raise
      end
    end
  
    def log_exception(worker, queue, ex, msg)
      
      log_with_context do |context|
        
        add_context(context, "sidekiq_worker", worker.class)
        add_context(context, "sidekiq_queue", queue.to_s)
        add_context(context, "sidekiq_args", msg['args'])
        add_context(context, "sidekiq_jid", worker.jid)
        
        # add in any extra payload data
        msg.each do |k, v|
          next if %w[class args].include?(k)
          add_context(context, "sidekiq_msg_#{k}", v)
        end

        error_logger = nil
        if Log4rExceptionable::Configuration.use_source_logger
          payload_class = worker.logger rescue nil
          if worker.logger.instance_of?(Log4r::Logger)
            error_logger = worker.logger
          end
        end
        
        error_logger ||= Log4rExceptionable::Configuration.sidekiq_failure_logger
        
        error_logger.send(Log4rExceptionable::Configuration.log_level, ex)
      end
      
    end

  end
    
end
