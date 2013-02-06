require "spec_helper"

describe Log4rExceptionable::SidekiqFailureHandler do
  include PerformSidekiqJob

  context "handling sidekiq failures" do

    class SomeJob
      include Sidekiq::Worker
      def perform(*args)
        raise "I failed"
      end
    end

    class SomeJobWithNilLogger
      include Sidekiq::Worker
      def logger
        nil
      end
      
      def perform(*args)
        raise "I failed"
      end
    end

    class SomeJobWithOtherLogger
      include Sidekiq::Worker
      def logger
        self
      end
      
      def perform(*args)
        raise "I failed"
      end
    end
    
    class SomeJobWithLogger
      include Sidekiq::Worker
      def logger
        Log4r::Logger["SomeJobWithLogger"] || Log4r::Logger.new("SomeJobWithLogger")
      end
      
      def perform(*args)
        raise "I failed"
      end
    end

    before(:each) do
      Sidekiq.server_middleware do |chain|
        chain.insert_before Sidekiq::Middleware::Server::Logging, Log4rExceptionable::SidekiqFailureHandler
      end
      
      Log4rExceptionable::Configuration.configure do |config|
        config.sidekiq_failure_logger = 'sidekiqlogger'
        config.use_source_logger = true
        config.context_inclusions = nil
        config.context_exclusions = nil
        config.log_level = :fatal
      end
    end
    
    it "triggers failure handler" do
      
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        msg.backtrace.first.should =~ /sidekiq_failure_handler_spec.rb/
        Log4r::MDC.get('sidekiq_worker').should == SomeJob
        Log4r::MDC.get('sidekiq_queue').should == "somequeue"
        Log4r::MDC.get('sidekiq_args').should == ["foo"]
      end
      
      lambda {
        run_job(SomeJob, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "uses default logger if job logger is nil" do
      
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('sidekiq_worker').should == SomeJobWithNilLogger
      end
      
      lambda {
        run_job(SomeJobWithNilLogger, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "uses default logger if job logger is not log4r" do
      
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('sidekiq_worker').should == SomeJobWithOtherLogger
      end
      
      lambda {
        run_job(SomeJobWithOtherLogger, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "uses job logger if set" do
      Log4r::Logger.new('SomeJobWithLogger')
      Log4r::Logger['sidekiqlogger'].should_not_receive(:fatal)
      Log4r::Logger['SomeJobWithLogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('sidekiq_worker').should == SomeJobWithLogger
      end
      
      lambda {
        run_job(SomeJobWithLogger, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "uses default logger if source logger disabled" do
      Log4rExceptionable::Configuration.use_source_logger = false
      
      Log4r::Logger.new('SomeJobWithLogger')
      Log4r::Logger['SomeJobWithLogger'].should_not_receive(:fatal)
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get('sidekiq_worker').should == SomeJobWithLogger
      end
      
      lambda {
        run_job(SomeJobWithLogger, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "only includes inclusions if set" do
      Log4rExceptionable::Configuration.context_inclusions = ['sidekiq_queue']
      
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should == ['sidekiq_queue']
      end
      
      lambda {
        run_job(SomeJob, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "excludes exclusions if set" do
      Log4rExceptionable::Configuration.context_exclusions = ['sidekiq_queue']
      
      Log4r::Logger['sidekiqlogger'].should_receive(:fatal) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
        Log4r::MDC.get_context.keys.should_not include 'sidekiq_queue'
      end
      
      lambda {
        run_job(SomeJob, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    it "logs with given log_level" do
      Log4rExceptionable::Configuration.log_level = :info
      
      Log4r::Logger['sidekiqlogger'].should_receive(:info) do |msg|
        msg.should be_instance_of RuntimeError
        msg.message.should == "I failed"
      end
      
      lambda {
        run_job(SomeJob, 'foo', :queue => :somequeue)
      }.should raise_error("I failed")
    end
    
    
  end
  
end
