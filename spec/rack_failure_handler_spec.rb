require "spec_helper"

describe Log4rExceptionable::RackFailureHandler do
  include Rack::Test::Methods

  class FakeController
    class << self
      attr_accessor :logger
    end
    def logger
      self.class.logger
    end
    def controller_name
      "foo"
    end
    def action_name
      "bar"
    end
  end
  
  class TestApp
    
    def call(env)
      error = env['PATH_INFO'] =~ /error/
      
      case env['PATH_INFO']
        when /nil_controller_logger/
          FakeController.logger = nil
          env['action_controller.instance'] = FakeController.new
          error = true
        when /other_controller_logger/
          FakeController.logger = Object.new
          env['action_controller.instance'] = FakeController.new
          error = true
        when /controller_logger/
          FakeController.logger = Log4r::Logger["ControllerLogger"] || Log4r::Logger.new("ControllerLogger")
          env['action_controller.instance'] = FakeController.new
          error = true
        when /nil_rack_logger/
          env['rack.logger'] = nil
          error = true
        when /other_rack_logger/
          env['rack.logger'] = Object.new
          error = true
        when /rack_logger/
          env['rack.logger'] = Log4r::Logger["RackLogger"] || Log4r::Logger.new("RackLogger")
          error = true
      end
      
      raise "I failed" if error
      return [200, {"Content-Type" => "text"}, ["hello"]]
    end
  end
  
  def app
    @app ||= Log4rExceptionable::RackFailureHandler.new(TestApp.new)
  end

  context "handling rack failures" do

    before(:each) do
      Log4rExceptionable::Configuration.configure do |config|
        config.rack_failure_logger = 'racklogger'
        config.use_source_logger = true
        config.context_inclusions = nil
        config.context_exclusions = nil
        config.log_level = :fatal
      end
    end
    
    it "doesn't log a failure with normal usage" do
      Log4r::Logger['racklogger'].should_not_receive(:fatal)
      get "/"
    end
    
    it "triggers failure handler" do
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        msg.backtrace.first.should =~ /rack_failure_handler_spec.rb/
        Log4r::MDC.get('rack_env_PATH_INFO').should == '/error'
      end
      
      lambda {
        get "/error"
      }.should raise_error("I failed")
    end
    
    it "uses default logger if controller logger is nil" do
      
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/nil_controller_logger"
      }.should raise_error("I failed")
    end
    
    it "uses default logger if controller logger is not log4r" do
      
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/other_controller_logger"
      }.should raise_error("I failed")
    end
    
    it "uses controller logger if set" do
      Log4r::Logger.new('ControllerLogger')
      Log4r::Logger['racklogger'].should_not_receive(:fatal)
      Log4r::Logger['ControllerLogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/controller_logger"
      }.should raise_error("I failed")
    end
    
    it "uses default logger if source logger disabled" do
      Log4rExceptionable::Configuration.use_source_logger = false
      Log4r::Logger.new('ControllerLogger')
      Log4r::Logger['ControllerLogger'].should_not_receive(:fatal)
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/controller_logger"
      }.should raise_error("I failed")
    end
    
    it "adds controller names if set" do
      Log4r::Logger.new('ControllerLogger')
      Log4r::Logger['ControllerLogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('rack_controller_name').should == 'foo'
        Log4r::MDC.get('rack_action_name').should == 'bar'
      end
      
      lambda {
        get "/controller_logger"
      }.should raise_error("I failed")
    end
    
    it "uses default logger if rack logger is nil" do
      
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/nil_rack_logger"
      }.should raise_error("I failed")
    end
    
    it "uses default logger if rack logger is not log4r" do
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/other_rack_logger"
      }.should raise_error("I failed")
    end
    
    it "uses rack logger if set" do
      Log4r::Logger.new('RackLogger')
      Log4r::Logger['racklogger'].should_not_receive(:fatal)
      Log4r::Logger['RackLogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/rack_logger"
      }.should raise_error("I failed")
    end
    
    it "only includes inclusions if set" do
      Log4rExceptionable::Configuration.context_inclusions = ['rack_env_rack.version']
      
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should == ['rack_env_rack.version']
      end
      
      lambda {
        get "/other_rack_logger"
      }.should raise_error("I failed")
      
    end

    it "excludes exclusions if set" do
      Log4rExceptionable::Configuration.context_exclusions = ['rack_env_rack.version']
      
      Log4r::Logger['racklogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should_not include 'rack_env_rack.version'
      end
      
      lambda {
        get "/other_rack_logger"
      }.should raise_error("I failed")
      
    end

    it "logs with given log_level" do
      Log4rExceptionable::Configuration.log_level = :info
      
      Log4r::Logger['racklogger'].should_receive(:info) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        get "/other_rack_logger"
      }.should raise_error("I failed")
    end
    
  end
  
end
