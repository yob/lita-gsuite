require 'spec_helper'

describe Lita::Commands::DeletionCandidates do
  describe "#run" do
    let(:cmd) { Lita::Commands::DeletionCandidates.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GoogleAppsGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:three_months_ago) { DateTime.now - (3*30) }
    let(:one_year_ago) { DateTime.now - 365 }
    let(:active_user_with_activity) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.user.with.activity@example.com",
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
    let(:suspended_user_inactive_for_three_months) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.user.with.activity@example.com",
        suspended: true,
        created_at: three_months_ago,
        last_login_at: three_months_ago,
        ou_path: "/AU",
        admin: false,
        delegated_admin: false,
        two_factor_enabled: false,
        two_factor_enforced: false,
      )
    }
    let(:suspended_user_with_no_recent_sign_in) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.user.with.activity@example.com",
        suspended: true,
        created_at: one_year_ago,
        last_login_at: one_year_ago,
        ou_path: "/AU",
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
          expect(robot).to have_received(:send_message).with(target, "No users found")
        end
      end
    end

    context "when the account has an active user who signed in recently" do
      before do
        allow(gateway).to receive(:users).and_return([active_user_with_activity])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No users found")
        end
      end
    end

    context "when the account has one suspended user who signed in 3 months ago" do
      before do
        allow(gateway).to receive(:users).and_return([suspended_user_inactive_for_three_months])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No users found")
        end
      end
    end

    context "when the account has one suspended user who signed in a year ago" do
      let(:expected_msg) {
        <<~EOS
        The following users are suspended, and have not logged in for 26 weeks. If appropriate, consider deleting their accounts:
        - /AU/active.user.with.activity@example.com
        EOS
      }
      before do
        allow(gateway).to receive(:users).and_return([suspended_user_with_no_recent_sign_in])
      end
      it "sends a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).with(target, expected_msg.strip)
      end
    end

  end
end

