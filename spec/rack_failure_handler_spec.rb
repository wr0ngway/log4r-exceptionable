require "spec_helper"

describe Log4rExceptionable::RackFailureHandler do
  include Rack::Test::Methods

  class TestApp
    def call(env)
      if env['PATH_INFO'] =~ /error/
        raise "I failed"
      else
        return [200, {"Content-Type" => "text"}, ["hello"]]
      end
    end
  end
  
  def app
    @app ||= Log4rExceptionable::RackFailureHandler.new(TestApp.new)
  end

  context "handling rack failures" do

    before(:all) do
      Log4rExceptionable::Configuration.configure do |config|
        config.rack_failure_logger = 'racklogger'
      end
    end
    
    it "doesn't log a failure with normal usage" do
      Log4r::Logger['racklogger'].should_not_receive(:error)
      get "/"
    end
    
    it "triggers failure handler" do
      Log4r::Logger['racklogger'].should_receive(:error) do |msg|
        msg.should == "RuntimeError: I failed"
        Log4r::MDC.get('rack_exception_backtrace').should =~ /rack_failure_handler_spec.rb/
        Log4r::MDC.get('rack_exception_backtrace').lines.to_a.size.should > 1
        Log4r::MDC.get('rack_exception_line').should =~ /\d+/
        Log4r::MDC.get('rack_exception_file').should =~ /rack_failure_handler_spec.rb/
        Log4r::MDC.get('rack_env_PATH_INFO').should == '"/error"'
      end
      
      lambda {
        get "/error"
      }.should raise_error("I failed")
    end
    
  end
  
end
