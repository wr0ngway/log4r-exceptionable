require "spec_helper"

describe Log4rExceptionable::Helper do
  include Log4rExceptionable::Helper
  
  context "helper" do

    before(:each) do
    end
    
    it "should raise if failsafe_logging false" do
      Log4rExceptionable::Configuration.failsafe_logging = false
      $stderr.should_not_receive(:puts)

      lambda {
        log_with_context do
          raise "I failed"
        end
      }.should raise_error("I failed")
    end
    
    it "should not raise if failsafe_logging true" do
      Log4rExceptionable::Configuration.failsafe_logging = true
      $stderr.should_receive(:puts)

      
      lambda {
        log_with_context do
          raise "I failed"
        end
      }.should_not raise_error("I failed")
    end

  end
  
end
