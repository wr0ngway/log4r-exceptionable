require "spec_helper"

describe Log4rExceptionable::Configuration do

  context "configure" do

    before(:each) do
      Log4rExceptionable::Configuration.rack_failure_logger = nil
      Log4rExceptionable::Configuration.resque_failure_logger = nil
      Log4rExceptionable::Configuration.sidekiq_failure_logger = nil
    end
    
    it "should raise if no logger in config" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
        end
      }.should raise_error("log4r-exceptionable requires a rack_failure_logger or resque_failure_logger or sidekiq_failure_logger")
    end

    it "should not raise if config has a rack logger" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.rack_failure_logger = 'mylogger'
        end
      }.should_not raise_exception
    end
    
    it "should not raise if config has a resque logger" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.resque_failure_logger = 'mylogger'
        end
      }.should_not raise_exception
    end
    
    it "should allow setting logger to string for pre-existing logger" do
      logger = Log4r::Logger.new('existinglogger')
      Log4rExceptionable::Configuration.configure do |config|
        config.rack_failure_logger = logger
      end
      
      Log4rExceptionable::Configuration.rack_failure_logger.should == Log4r::Logger['existinglogger']
      Log4rExceptionable::Configuration.rack_failure_logger.should == logger
    end
    
    it "should allow setting logger to string for non-existing logger" do
      Log4r::Logger['newlogger'].should be_nil

      Log4rExceptionable::Configuration.configure do |config|
        config.rack_failure_logger = "newlogger"
      end
      
      Log4rExceptionable::Configuration.rack_failure_logger.should == Log4r::Logger['newlogger']
    end
    
    it "should allow setting logger to logger instance" do
      Log4rExceptionable::Configuration.configure do |config|
        config.rack_failure_logger = Log4r::Logger.new('otherlogger')
      end
      
      Log4rExceptionable::Configuration.rack_failure_logger.should == Log4r::Logger['otherlogger']
    end
    
    it "should raise if invalid log_level" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.rack_failure_logger = "mylogger"
          config.log_level = nil
        end
      }.should raise_error("Invalid log level: ")

      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.rack_failure_logger = "mylogger"
          config.log_level = :foobar
        end
      }.should raise_error("Invalid log level: foobar")
    end

    it "should allow setting valid log_level" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.rack_failure_logger = "mylogger"
          config.log_level = :debug
        end
      }.should_not raise_error
    end

  end
  
end
