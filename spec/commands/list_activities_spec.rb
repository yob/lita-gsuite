require 'spec_helper'

describe Lita::Commands::ListActivities do
  describe "#run" do
    let(:cmd) { Lita::Commands::ListActivities .new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GoogleAppsGateway) }
    let(:one_hour_ago) { (Time.now - (60*60)).utc.to_datetime }
    let(:twenty_minutes_ago) { (Time.now - (20*60)).utc.to_datetime }
    let(:ten_minutes_ago) { (Time.now - (10*60)).utc.to_datetime }
    let(:activity) {
      Lita::GoogleActivity.new(
        time: one_hour_ago,
        actor: "ellie@hi.com",
        ip: "1.1.1.1",
        name: "Add group member",
        params: {
          "USER_EMAIL"=>"foo@bar.com", "GROUP_EMAIL"=>"bargroup@foo.com"
        }
      )
    }

    before do
      allow(robot).to receive(:send_message)
    end

    context "when the account had activity in the time window" do
      before do
        allow(gateway).to receive(:admin_activities).and_return([])
      end
      it "calls the gateway with correct arguments" do
        cmd.run(robot, target, gateway, ten_minutes_ago, twenty_minutes_ago)
        expect(gateway).to have_received(:admin_activities).once.with(twenty_minutes_ago, ten_minutes_ago)
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway, ten_minutes_ago, twenty_minutes_ago)
        expect(robot).to_not have_received(:send_message)
      end
    end

    context "when the account has one activity in the time window" do
      let(:one_hour_ago_formatted) { one_hour_ago.httpdate } 
      let(:expected_msg) {
        "Date: #{one_hour_ago_formatted}\n" +
          "Admin User: ellie@hi.com\n" +
          "Action: Add group member\n" + 
          "USER EMAIL: foo@bar.com\n" +
          "GROUP EMAIL: bargroup@foo.com\n"
      }
      before do
        allow(gateway).to receive(:admin_activities).and_return([activity])
      end
      it "calls the gateway with correct arguments" do
        cmd.run(robot, target, gateway, ten_minutes_ago, twenty_minutes_ago)
        expect(gateway).to have_received(:admin_activities).once.with(twenty_minutes_ago, ten_minutes_ago)
      end
      it "sends a message with the activity details" do
        cmd.run(robot, target, gateway, ten_minutes_ago, twenty_minutes_ago)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
    end
  end
end

