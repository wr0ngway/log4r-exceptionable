
module Log4rExceptionable
    
  # A rack middleware handler that logs exceptions with log4r
  #
  class RackFailureHandler
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
      begin
        mdc = Log4r::MDC
        original_mdc = mdc.get_context
        
        begin
          message = "#{exception.class}: #{exception.message}"
          
          mdc.put('rack_exception', exception.class.name)
          trace = Array(exception.backtrace)
          if trace.size > 0
            message << "\n"
            message << trace.join("\n")

            file, line = trace[0].split(":")
            mdc.put('rack_exception_file', file)
            mdc.put('rack_exception_line', line.to_i)
          end
    
          if env and env.size > 0
            env.each do |k, v|
              begin
                mdc.put("rack_env_#{k}", v.inspect)
              rescue
              end
            end
          end
          
          controller = env['action_controller.instance']
          if controller && controller.respond_to?(:logger) && controller.logger.instance_of?(Log4r::Logger)
            error_logger = controller.logger 
          elsif env['rack.logger'] && env['rack.logger'].instance_of?(Log4r::Logger)
            error_logger = env['rack.logger']
          else
            error_logger = Log4rExceptionable::Configuration.rack_failure_logger
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
        puts "Log4r Exceptionable could not log rack exception: " + e.message
      end
    end
  
  end

end
