
module Log4rExceptionable
    
  # A rack middleware handler that logs exceptions with log4r
  #
  class RackFailureHandler
    
    include Log4rExceptionable::Helper
    
    attr_reader :args
  
    def initialize(app, opts = {})
      @app = app
    end
  
    def call(env)
      # Make thread safe
      dup._call(env)
    end
  
    def _call(env)
      begin
        # Call the app we are monitoring
        response = @app.call(env)
      rescue => exception
        # An exception has been raised. Send to log4r
        send_to_log4r(exception, env)
  
        # Raise the exception again to pass back to app.
        raise
      end
  
      if env['rack.exception']
        send_to_log4r(env['rack.exception'], env)
      end
  
      response
    end
  
    def send_to_log4r(exception, env=nil)
      
      log_with_context do |context|
        
        # add rack env to context so our logger can report with that data 
        if env and env.size > 0
          env.each do |k, v|
            begin
              add_context(context, "rack_env_#{k}", v)
            rescue => e
              $stderr.puts "Log4r Exceptionable could not extract a rack env item: " + e.message
            end
          end
        end

        # Determine exception source class if possible, and use its logger if configured to do so.
        error_logger = nil
        if Log4rExceptionable::Configuration.use_source_logger
          controller = env['action_controller.instance']
          if controller && controller.respond_to?(:logger) && controller.logger.instance_of?(Log4r::Logger)
            error_logger = controller.logger 
            begin
              add_context(context, "rack_controller_name", controller.controller_name)
              add_context(context, "rack_action_name", controller.action_name)
            rescue => e
              $stderr.puts "Log4r Exceptionable could not extract controller names: " + e.message
            end
          elsif env['rack.logger'] && env['rack.logger'].instance_of?(Log4r::Logger)
            error_logger = env['rack.logger']
          end
        end
        
        error_logger ||= Log4rExceptionable::Configuration.rack_failure_logger
        
        error_logger.send(Log4rExceptionable::Configuration.log_level, exception)
        
      end
      
    end
    
  end

end
