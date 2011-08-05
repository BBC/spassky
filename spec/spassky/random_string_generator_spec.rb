require 'spec_helper'
require 'spassky/random_string_generator'

module Spassky
  describe RandomStringGenerator do
    it "returns the current ticks" do
      now = mock
      now.stub!(:to_i).and_return(123)
      Time.stub!(:now).and_return(now)
      RandomStringGenerator.random_string.should == "123"
    end
  end
end