require "spec_helper"

describe Log4rExceptionable::ResqueFailureHandler do
  include PerformJob

  context "handling resque failures" do

    class SomeJob
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
        msg.should == "RuntimeError: I failed"
        Log4r::MDC.get('resque_exception_backtrace').should =~ /resque_failure_handler_spec.rb/
        Log4r::MDC.get('resque_exception_backtrace').lines.to_a.size.should > 1
        Log4r::MDC.get('resque_exception_line').should =~ /\d+/
        Log4r::MDC.get('resque_exception_file').should =~ /resque_failure_handler_spec.rb/
        Log4r::MDC.get('resque_worker').should == ""
        Log4r::MDC.get('resque_queue').should == "somequeue"
        Log4r::MDC.get('resque_class').should == "SomeJob"
        Log4r::MDC.get('resque_args').should == "[\"foo\"]"
      end
      
      run_resque_job(SomeJob, 'foo', :queue => :somequeue, :inline => true)
    end
    
  end
  
end
