require "log4r"
require "log4r-exceptionable/version"
require "log4r-exceptionable/configuration"
require "log4r-exceptionable/helper"

# optional if only using resque
begin
  require "log4r-exceptionable/rack_failure_handler"
rescue LoadError
end

# optional if only using sidekiq
begin
  require "log4r-exceptionable/sidekiq_failure_handler"
rescue LoadError
end

# optional if only using rack
begin
  require "log4r-exceptionable/resque_failure_handler"
rescue LoadError
end
