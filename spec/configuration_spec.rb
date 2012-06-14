require "spec_helper"

describe Log4rExceptionable::Configuration do

  context "configure" do

    it "should raise if no logger in config" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
        end
      }.should raise_error("log4r-exceptionable requires a rack_failure_logger or resque_failure_logger")
    end

    it "should not raise if config valid" do
      lambda {
        Log4rExceptionable::Configuration.configure do |config|
          config.rack_failure_logger = 'mylogger'
        end
      }.should_not raise_exception
      Log4rExceptionable::Configuration.rack_failure_logger = nil
      
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
    
  end
  
end
