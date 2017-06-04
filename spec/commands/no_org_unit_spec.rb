require 'spec_helper'

describe Lita::Commands::NoOrgUnit do
  describe "#run" do
    let(:cmd) { Lita::Commands::NoOrgUnit.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GsuiteGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:active_no_ou) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/",
        admin: false,
        delegated_admin: true,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:suspended_no_ou) {
      Lita::GoogleUser.new(
        id: "2",
        full_name: "Suspended User",
        email: "suspended@example.com",
        suspended: true,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/",
        admin: false,
        delegated_admin: true,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:active_with_ou) {
      Lita::GoogleUser.new(
        id: "3",
        full_name: "Active OU",
        email: "active.ou@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/AU",
        admin: false,
        delegated_admin: true,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }

    before do
      allow(robot).to receive(:send_message)
    end

    context "when the account has no users" do
      before do
        allow(gateway).to receive(:users).and_return([])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No users are missing an org unit")
        end
      end
    end

    context "when the account has some users" do
      let(:expected_msg) {
        "The following users are not assigned to an organisational unit:\n" +
        "- active@example.com"
      }
      before do
        allow(gateway).to receive(:users).and_return([active_no_ou, suspended_no_ou, active_with_ou])
      end
      it "sends a message with the target users" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
    end
  end
end
