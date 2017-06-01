require 'spec_helper'

describe Lita::Commands::TwoFactorStats do
  describe "#run" do
    let(:cmd) { Lita::Commands::TwoFactorStats.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GoogleAppsGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:active_au_user_tfa_on) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.au.tfa.on@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/AU",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: true,
        two_factor_enforced: false,
      )
    }
    let(:active_au_user_tfa_off) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.au.tfa.off@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/AU",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:suspended_au_user_tfa_off) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "suspended.au.tfa.off@example.com",
        suspended: true,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/AU",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:active_uk_user_tfa_on) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.uk.tfa.on@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/UK",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: true,
        two_factor_enforced: false,
      )
    }
    let(:active_us_user_tfa_off) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.us.tfa.on@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/US",
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
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No stats found")
        end
      end
    end

    context "when the account has some users" do
      let(:expected_msg) {
        "Active users with Two Factor Authentication enabled:\n\n" +
          "- /AU 1/2 (50.0%)\n" + 
          "- /UK 1/1 (100.0%)\n" + 
          "- /US 0/1 (0.0%)\n" +
          "- Overall 2/4 (50.0%)"
      }
      before do
        allow(gateway).to receive(:users).and_return(
          [
            active_au_user_tfa_on,
            active_au_user_tfa_off,
            active_uk_user_tfa_on,
            active_us_user_tfa_off,
            suspended_au_user_tfa_off
          ]
        )
      end
      it "sends a message with the target users" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
    end
  end
end
