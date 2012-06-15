graylog2-resque
===============

This gem provides failure handlers for [Resque][0] and [Rack][1] that logs all failures using [log4r][2].  It is expected that these logs will get sent elsewhere (e.g. [graylog][3]) by using log4r outputters (e.g. [log4r-gelf][4]).  It adds contextual information to the log message using Log4r::MDC, which is useful if you are using log4r-gelf since it sends all of those to graylog as custom attributes. 

[![Build Status](https://secure.travis-ci.org/wr0ngway/log4r-exceptionable.png)](http://travis-ci.org/wr0ngway/log4r-exceptionable)

Install
-------

    gem install log4r-exceptionable
or add to your Gemfile 

To use
------

Add to some initializer code:

    Log4rExceptionable::Configuration.configure do |config|
      
      # The default loggers used when a source logger is not available
      # required (at least one logger needs to be set, but you don't need
      # to set rack if using resque, and vice versa)
      #
      config.rack_failure_logger = "rails::SomeRackLogger"
      config.resque_failure_logger = "rails::SomeResqueLogger"

      # Prevent the detection and use of the source class's logger
      # The source logger is taken from the resque class raising
      # the exception, rails controller raising the exception,
      # or rack_env['rack.logger']
      # optional (defaults to true)
      #
      # config.use_source_logger = false
      
    end
  
    Rails.application.config.middleware.use "Log4rExceptionable::RackFailureHandler"
    Resque::Failure.backend = Log4rExceptionable::ResqueFailureHandler

All failures will be logged using the source logger or the given logger if a source is not available. The logger can be set using their log4r fullname or a log4r logger instance.

Author
------

Matt Conway :: matt@conwaysplace.com :: @mattconway

Copyright
---------

Copyright (c) 2012 Matt Conway. See LICENSE for details.

[0]: http://github.com/defunkt/resque
[1]: http://rack.github.com/
[2]: http://log4r.rubyforge.org/
[3]: http://graylog2.org/
[4]: http://github.com/wr0ngway/log4r-gelf

