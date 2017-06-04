require 'spec_helper'

describe Lita::Commands::ListAdmins do
  describe "#run" do
    let(:cmd) { Lita::Commands::ListAdmins.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GsuiteGateway) }
    let(:one_week_ago) { DateTime.now - 7 }
    let(:delegated_admin) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Delegated Admin",
        email: "delegated@example.com",
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
    let(:super_admin) {
      Lita::GoogleUser.new(
        id: "1",
        full_name: "Super Admin",
        email: "super@example.com",
        suspended: false,
        created_at: one_week_ago,
        last_login_at: one_week_ago,
        ou_path: "/AU",
        admin: true,
        delegated_admin: false,
        two_factor_enabled: true,
        two_factor_enforced: false,
      )
    }

    before do
      allow(robot).to receive(:send_message)
    end

    context "when the account has no admins" do
      before do
        allow(gateway).to receive(:delegated_admins).and_return([])
        allow(gateway).to receive(:super_admins).and_return([])
      end
      it "doesn't send a message" do
        cmd.run(robot, target, gateway)
        expect(robot).to_not have_received(:send_message)
      end
      context "with negative_ack enabled" do
        it "sends a nack message" do
          cmd.run(robot, target, gateway, negative_ack: true)
          expect(robot).to have_received(:send_message).with(target, "No admins found")
        end
      end
    end

    context "when the account has one super admin and one delegated admin" do
      let(:expected_msg) {
        "The following groups have no members, which may result in undelivered email.\n- test2@example.com"
        "The following accounts have administrative privileges:\n" +
          "- /AU/delegated@example.com (2fa enabled: N)\n" +
          "- /AU/super@example.com (2fa enabled: Y)"
      }
      before do
        allow(gateway).to receive(:delegated_admins).and_return([delegated_admin])
        allow(gateway).to receive(:super_admins).and_return([super_admin])
      end
      it "sends a message listing the admins" do
        cmd.run(robot, target, gateway)
        expect(robot).to have_received(:send_message).once.with(target, expected_msg)
      end
    end
  end
end
