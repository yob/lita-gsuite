require 'spec_helper'

describe Lita::GoogleActivity do
  let(:activity) { Lita::GoogleActivity.new(
    time: Time.utc(2016, 6, 14, 2, 27, 48),
    actor: "ellie@hi.com",
    ip: "1.1.1.1",
    name: "ADD_GROUP_MEMBER",
    params: {
      "USER_EMAIL"=>"rafael.sarralde@theconversation.com", "GROUP_EMAIL"=>"spain@theconversation.com"
    }
  )}
  describe "#to_msg" do
    it "returns helpful string" do
      expect(activity.to_msg).to eq '2016-06-14T02:27:48Z ellie@hi.com ADD_GROUP_MEMBER: {"USER_EMAIL"=>"rafael.sarralde@theconversation.com", "GROUP_EMAIL"=>"spain@theconversation.com"}'
    end
  end
end
