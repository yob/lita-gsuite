require 'spec_helper'

describe Lita::GoogleActivity do
  let(:activity) { Lita::GoogleActivity.new(
    time: Time.utc(2016, 6, 14, 2, 27, 48),
    actor: "ellie@hi.com",
    ip: "1.1.1.1",
    name: "Add group member",
    params: {
      "USER_EMAIL"=>"foo@bar.com", "GROUP_EMAIL"=>"bargroup@foo.com"
    }
  )}
  describe "#to_msg" do
    it "returns helpful string" do
      expect(activity.to_msg).to eq(
        <<~EOF
          Date: Tue, 14 Jun 2016 02:27:48 GMT
          Admin User: ellie@hi.com
          Action: Add group member => foo@bar.com (user email) to bargroup@foo.com (group email)
        EOF
      )
    end
  end
end
