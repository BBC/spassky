require 'spec_helper'
require 'spassky/test_result'

module Spassky
  describe TestResult do
    context "when no devices are connected" do
      it "is in progress" do
        TestResult.new([]).status.should == "in progress"
      end
    end

    context "when one device passes" do
      it "outputs a summary" do
        test_result = TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'pass', 'test')
        ])
        test_result.summary.should == "1 test passed on 1 device"
      end
    end

    context "when all devices pass" do
      it "is a pass" do
        TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'pass', 'test'),
          Spassky::DeviceTestStatus.new('agent2', 'pass', 'test')
        ]).status.should == "pass"
      end

      it "outputs a pluralised summary" do
        test_result = TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'pass', 'test'),
          Spassky::DeviceTestStatus.new('agent2', 'pass', 'test')
        ])
        test_result.summary.should == "1 test passed on 2 devices"
      end
    end

    context "when any device fails" do
      it "is a fail" do
        TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'pass', 'test'),
          Spassky::DeviceTestStatus.new('agent2', 'fail', 'test')
        ]).status.should == "fail"
      end

      it "outputs a summary" do
        test_result = TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'fail', 'test')
        ])
        test_result.summary.should == "1 test failed on 1 device"
      end
    end

    context "when any test is still in progress" do
      it "is a fail" do
        TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'pass', 'test'),
          Spassky::DeviceTestStatus.new('agent2', 'fail', 'test'),
          Spassky::DeviceTestStatus.new('agent3', 'in progress', 'test')
        ]).status.should == "in progress"
      end
    end

    context "when 1 test times out" do
      it "outputs the correct summary" do
        test_result = TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'timed out', 'test')
        ])
        test_result.summary.should == "1 test timed out on 1 device"
      end

      it "has the status 'timed out'" do
        test_result = TestResult.new([
          Spassky::DeviceTestStatus.new('agent1', 'timed out', 'test'),
          Spassky::DeviceTestStatus.new('agent2', 'pass', 'test')
        ])
        test_result.status.should == "timed out"
      end
    end

    it "can be serialized and deserialized" do
      test_result = TestResult.new([Spassky::DeviceTestStatus.new('agent', 'pass', 'test')])
      json = test_result.to_json
      deserialized = TestResult.from_json(json)
      deserialized.device_statuses.size.should == 1
      deserialized.device_statuses.first.user_agent.should == 'agent'
      deserialized.device_statuses.first.status.should == 'pass'      
    end

    describe "#completed_since(nil)" do
      it "returns all device test results that are not in progress" do
        status_1 = Spassky::DeviceTestStatus.new('agent', 'pass', 'test1')
        status_2 = Spassky::DeviceTestStatus.new('agent', 'in progress', 'test2')
        status_3 = Spassky::DeviceTestStatus.new('agent', 'fail', 'test3')
        test_result = TestResult.new([status_1, status_2, status_3])
        test_result.completed_since(nil).should == [status_1, status_3]
      end
    end

    describe "#completed_since(other_test_result)" do
      it "returns all device test results that are no longer in progress" do
        status_a1 = Spassky::DeviceTestStatus.new('agent', 'pass', 'test1')
        status_a2 = Spassky::DeviceTestStatus.new('agent', 'in progress', 'test2')
        status_a3 = Spassky::DeviceTestStatus.new('agent', 'in progress', 'test3')
        status_b1 = Spassky::DeviceTestStatus.new('agent', 'pass', 'test1')
        status_b2 = Spassky::DeviceTestStatus.new('agent', 'fail', 'test2')
        status_b3 = Spassky::DeviceTestStatus.new('agent', 'timed out', 'test3')

        test_result_before = TestResult.new([status_a1, status_a2, status_a3])
        test_result_after  = TestResult.new([status_b1, status_b2, status_b3])

        test_result_after.completed_since(test_result_before).should == [status_b2, status_b3]
      end
    end
  end
end
