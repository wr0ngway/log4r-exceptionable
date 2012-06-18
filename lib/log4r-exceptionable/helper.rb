module Log4rExceptionable
    
  # Configuration for the failure backends that log exceptions with log4r
  #
  module Helper
    
    def log_with_context
      begin
        mdc = Log4r::MDC
        original_mdc = mdc.get_context
        
        begin
          yield mdc
        ensure
          # Since this is somewhat of a global map, clean the keys
          # we put in so other log messages don't see them
          mdc.get_context.keys.each do |k|
            mdc.remove(k) unless original_mdc.has_key?(k)
          end
        end
        
      rescue => e
        $stderr.puts "Log4r Exceptionable could not log exception: " + e.message
      end
    end

    def add_context(context, key, value)
      inclusions = Log4rExceptionable::Configuration.context_inclusions
      exclusions = Log4rExceptionable::Configuration.context_exclusions
      
      return if inclusions && ! inclusions.include?(key)
      
      if exclusions
        if ! exclusions.include?(key)
          context.put(key, value)
        end
      else
        context.put(key, value)
      end
    end
    
  end
  
end
