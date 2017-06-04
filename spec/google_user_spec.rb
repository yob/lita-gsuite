require 'spec_helper'

describe Lita::GoogleUser do
  let(:one_week_ago) { DateTime.now - 7 }
  let(:root_user) {
    Lita::GoogleUser.new(
      id: "1",
      full_name: "Root User",
      email: "root.user@example.com",
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
  let(:ou_user) {
    Lita::GoogleUser.new(
      id: "2",
      full_name: "OU User",
      email: "ou.user@example.com",
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
  describe "#path" do
    context "with a root level user" do
      it "returns their email prefixed with a /" do
        expect(root_user.path).to eq("/root.user@example.com")
      end
    end
    context "with a user in an OU" do
      it "returns their email prefixed with their OU path" do
        expect(ou_user.path).to eq("/AU/ou.user@example.com")
      end
    end
  end
end
