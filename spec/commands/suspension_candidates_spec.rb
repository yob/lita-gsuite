require 'spec_helper'

describe Lita::Commands::SuspensionCandidates do
  describe "#run" do
    let(:cmd) { Lita::Commands::SuspensionCandidates.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GsuiteGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:three_months_ago) { DateTime.now - (3*30) }
    let(:active_user_last_seen_one_week_ago) {
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
    let(:suspended_user_last_seen_three_months_ago) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Suspended User",
        email: "suspended.user@example.com",
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
    let(:active_user_last_seen_three_months_ago) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Active User",
        email: "active.user.gone.quiet@example.com",
        suspended: false,
        created_at: three_months_ago,
        last_login_at: three_months_ago,
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
        allow(gateway).to receive(:users).and_return([active_user_last_seen_one_week_ago])
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
        allow(gateway).to receive(:users).and_return([suspended_user_last_seen_three_months_ago])
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

    context "when the account has one active user who signed in 3 months ago" do
      let(:expected_msg) {
        <<~EOS
        The following users have active accounts, but have not logged in for 8 weeks. If appropriate, consider suspending or deleting their accounts:
        - /AU/active.user.gone.quiet@example.com
        EOS
      }
      before do
        allow(gateway).to receive(:users).and_return([active_user_last_seen_three_months_ago])
      end
      it "sends a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).with(target, expected_msg.strip)
      end
    end

  end
end

