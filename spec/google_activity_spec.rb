require 'spec_helper'

describe Lita::GoogleActivity do
  let(:activity) {
    Lita::GoogleActivity.new(
      time: Time.utc(2016, 6, 14, 2, 27, 48),
      actor: "ellie@hi.com",
      ip: "1.1.1.1",
      name: "Add group member",
      params: {
        "USER_EMAIL"=>"foo@bar.com", "GROUP_EMAIL"=>"bargroup@foo.com"
      }
    )
  }
  describe "#to_msg" do
    it "returns helpful string" do
      expect(activity.to_msg).to eq(
        <<~EOF
          Date: Tue, 14 Jun 2016 02:27:48 GMT
          Admin User: ellie@hi.com
          Action: Add group member
          USER EMAIL: foo@bar.com
          GROUP EMAIL: bargroup@foo.com
        EOF
      )
    end
  end

  describe "#from_api" do
    let(:api_id) {
      instance_double(Google::Apis::AdminReportsV1::Activity::Id, time: DateTime.new(2017,11,23,0,0,0))
    }
    let(:api_actor) {
      instance_double(Google::Apis::AdminReportsV1::Activity::Actor, email: "test@example.com")
    }
    let(:api_parameter) {
      instance_double(Google::Apis::AdminReportsV1::Activity::Event::Parameter, name: "Test Param", value: 123)
    }
    let(:api_event) {
      instance_double(Google::Apis::AdminReportsV1::Activity::Event, name: "Test", parameters: [api_parameter])
    }
    let(:api_item) {
      instance_double(Google::Apis::AdminReportsV1::Activity, id: api_id, actor: api_actor, ip_address: "1.2.3.4", events: [api_event])
    }
    let(:activity) { Lita::GoogleActivity.from_api(api_item).first}

    context "a Google::Apis::AdminReportsV1::Activity with parameters" do
      it "initializes a new GoogleActivity with the right values" do
        expect(activity.time).to eq(DateTime.new(2017,11,23,0,0,0))
        expect(activity.actor).to eq("test@example.com")
        expect(activity.ip).to eq("1.2.3.4")
        expect(activity.name).to eq("Test")
        expect(activity.params).to eq({"Test Param"=>123})
      end
    end

    context "a Google::Apis::AdminReportsV1::Activity with nil parameters" do
      let(:api_event) {
        instance_double(Google::Apis::AdminReportsV1::Activity::Event, name: "Test", parameters: nil)
      }

      it "initializes a new GoogleActivity with the right values" do
        expect(activity.time).to eq(DateTime.new(2017,11,23,0,0,0))
        expect(activity.actor).to eq("test@example.com")
        expect(activity.ip).to eq("1.2.3.4")
        expect(activity.name).to eq("Test")
        expect(activity.params).to eq({})
      end
    end

  end
end
