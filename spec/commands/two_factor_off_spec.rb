require 'spec_helper'

describe Lita::Commands::TwoFactorOff do
  describe "#run" do
    let(:cmd) { Lita::Commands::TwoFactorOff.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GoogleAppsGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:active_user_tfa_on) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.tfa.on@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: true,
        two_factor_enforced: false,
      )
    }
    let(:suspended_user_tfa_off) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "suspended.tfa.off@example.com",
        suspended: true,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:active_user_tfa_off) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.tfa.off@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:active_user_tfa_off_wrong_ou) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.tfa.off@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/Test",
        admin: false,
        delegated_admin: false,
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
        let(:expected_msg) { "All users in / have Two Factor Authentication enabled"}
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, expected_msg)
        end
      end
    end

    context "when the account has some users" do
      let(:expected_msg) {
        "Users in / with Two Factor Authentication disabled:\n\n" +
          "- active.tfa.off@example.com\n"
      }
      before do
        allow(gateway).to receive(:users).and_return(
          [active_user_tfa_on, active_user_tfa_off, active_user_tfa_off_wrong_ou, suspended_user_tfa_off]
        )
      end
      it "sends a message with the target users" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
    end
  end
end
