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

    before(:each) do
      Log4rExceptionable::Configuration.configure do |config|
        config.resque_failure_logger = 'resquelogger'
        config.use_source_logger = true
        config.context_inclusions = nil
        config.context_exclusions = nil
        config.log_level = :fatal
      end
      
      Resque::Failure.backend = Log4rExceptionable::ResqueFailureHandler
    end
    
    it "triggers failure handler" do
      
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
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
      
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithNilLogger
      end
      
      run_resque_job(SomeJobWithNilLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses default logger if job logger is not log4r" do
      
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithOtherLogger
      end
      
      run_resque_job(SomeJobWithOtherLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses job logger if set" do
      Log4r::Logger.new('SomeJobWithLogger')
      Log4r::Logger['resquelogger'].should_not_receive(:fatal)
      Log4r::Logger['SomeJobWithLogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithLogger
      end
      
      run_resque_job(SomeJobWithLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "uses default logger if source logger disabled" do
      Log4rExceptionable::Configuration.use_source_logger = false
      
      Log4r::Logger.new('SomeJobWithLogger')
      Log4r::Logger['SomeJobWithLogger'].should_not_receive(:fatal)
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('resque_class').should == SomeJobWithLogger
      end
      
      run_resque_job(SomeJobWithLogger, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "only includes inclusions if set" do
      Log4rExceptionable::Configuration.context_inclusions = ['resque_queue']
      
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should == ['resque_queue']
      end
      
      run_resque_job(SomeJob, 'foo', :queue => :somequeue, :inline => true)
    end

    it "excludes exclusions if set" do
      Log4rExceptionable::Configuration.context_exclusions = ['resque_queue']
      
      Log4r::Logger['resquelogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should_not include 'resque_queue'
      end
      
      run_resque_job(SomeJob, 'foo', :queue => :somequeue, :inline => true)
    end
    
    it "logs with given log_level" do
      Log4rExceptionable::Configuration.log_level = :info
      
      Log4r::Logger['resquelogger'].should_receive(:info) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      run_resque_job(SomeJob, 'foo', :queue => :somequeue, :inline => true)
    end
    
    
  end
  
end
