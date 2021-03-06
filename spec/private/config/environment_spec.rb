require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Config do
  it "should apply environment from the command line option --environment" do
    Merb.start %w( --environment performance_testing -a runner )
    Merb.environment.should == "performance_testing"
  end

  it "should apply environment from the command line option -e" do
    Merb.start %w( -e selenium -a runner )
    Merb.environment.should == "selenium"
  end  
end