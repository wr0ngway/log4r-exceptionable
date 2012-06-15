require "spec_helper"

describe Log4rExceptionable::ResqueFailureHandler do
  include PerformJob

  context "handling resque failures" do

    class SomeJob
      def self.perform(*args)
        raise "I failed"
      end
    end

    class SomeJobWithNilLogger
      def self.logger
        nil
      end
      
      def self.perform(*args)
        raise "I failed"
      end
    end

    class SomeJobWithOtherLogger
      def self.logger
        self
      end
      
      def self.perform(*args)
        raise "I failed"
      end
    end
    
    class SomeJobWithLogger
      def self.logger
        Log4r::Logger["SomeJobWithLogger"] || Log4r::Logger.new("SomeJobWithLogger")
      end
      
      def self.perform(*args)
        raise "I failed"
      end
    end

    before(:all) do
      Log4rExceptionable::Configuration.configure do |config|
        config.resque_failure_logger = 'resquelogger'
      end
      
      Resque::Failure.backend = Log4rExceptionable::ResqueFailureHandler
    end
    
    it "triggers failure handler" do
      
      Log4r::Logger['resquelogger'].should_receive(:error) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        msg.backtrace.first.should =~ /resque_failure_handler_spec.rb/
        Log4r::MDC.get('resque_worker').should == nil
        Log4r::MDC.get('resque_queue').should == "somequeue"
        Log4r::MDC.get('resque_class').should == SomeJob
        Log4r::MDC.get('resque_args').should == ["foo"]
      end
      
      run_resque_job(SomeJob, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses default logger if job logger is nil" do
      
      Log4r::Logger['resquelogger'].should_receive(:error) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithNilLogger
      end
      
      run_resque_job(SomeJobWithNilLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses default logger if job logger is not log4r" do
      
      Log4r::Logger['resquelogger'].should_receive(:error) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithOtherLogger
      end
      
      run_resque_job(SomeJobWithOtherLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses job logger if set" do
      Log4r::Logger.new('SomeJobWithLogger')
      Log4r::Logger['resquelogger'].should_not_receive(:error)
      Log4r::Logger['SomeJobWithLogger'].should_receive(:error) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithLogger
      end
      
      run_resque_job(SomeJobWithLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
  end
  
end
