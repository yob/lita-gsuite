require 'spec_helper'

describe Lita::Commands::EmptyGroups do
  describe "#run" do
    let(:cmd) { Lita::Commands::EmptyGroups.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GsuiteGateway) }
    let(:group_with_members) {
      Lita::GoogleGroup.new(
        id: "1",
        email: "test@example.com",
        name: "test",
        member_count: 1,
        description: "test group"
      )
    }
    let(:empty_group) {
      Lita::GoogleGroup.new(
        id: "2",
        email: "test2@example.com",
        name: "test2",
        member_count: 0,
        description: "test2 group"
      )
    }

    before do
      allow(robot).to receive(:send_message)
    end

    context "when the account has no groups" do
      before do
        allow(gateway).to receive(:groups).and_return([])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No groups found")
        end
      end
    end

    context "when the account has a group but it's not empty" do
      before do
        allow(gateway).to receive(:groups).and_return([group_with_members])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No groups found")
        end
      end
    end

    context "when the account has groups and one of them are empty" do
      let(:expected_msg) {
        "The following groups have no members, which may result in undelivered email.\n- test2@example.com"
      }
      before do
        allow(gateway).to receive(:groups).and_return([group_with_members, empty_group])
      end
      it "sends a message with the empty group" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
      context "with negative_ack enabled" do
        it "sends a message with the empty group" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).once.with(target, expected_msg)
        end
      end
    end
  end
end
