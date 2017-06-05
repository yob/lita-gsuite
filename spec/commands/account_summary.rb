require 'spec_helper'

describe Lita::Commands::AccountSummary do
  describe "#run" do
    let(:cmd) { Lita::Commands::AccountSummary.new }
    let(:robot) { instance_double(Lita::Robot) }
    let(:target) { instance_double(Lita::Source) }
    let(:gateway) { instance_double(Lita::GsuiteGateway) }
    let(:created_at) { DateTime.parse("2017-06-07 12:34:56") }
    let(:account) {
      Lita::GoogleAccount.new(
        id: "123",
        alternate_email: "user@foo.com",
        primary_domain: "example.com",
        created_at: created_at,
        language: "en",
        phone_number: "+11231231234",
        address_line1: "1 Swanston St",
        address_line2: "Melbourne",
        address_line3: nil,
        contact_name: "Joe Admin",
        country_code: "AU",
        organization_name: "Testing Inc.",
        postal_code: "3000",
        region: nil
      )
    }
    let(:expected_msg) {
      "GSuite Account Summary - incorrect or out-of-date details can be updated at https://admin.google.com\n\n" +
        "ID: 123\n" +
        "Alternate Email: user@foo.com\n" +
        "Created At: 2017-06-07T12:34:56+00:00\n" +
        "Primary Domain: example.com\n" +
        "Language: en\n" +
        "Phone Number: +11231231234\n" +
        "Address: 1 Swanston St, Melbourne, 3000, AU\n" +
        "Contact Name: Joe Admin\n"
    }

    before do
      allow(robot).to receive(:send_message)
      allow(gateway).to receive(:account_summary).and_return(account)
    end

    it "sends a message" do
      cmd.run(robot, target, gateway)
      expect(robot).to have_received(:send_message).with(target, expected_msg)
    end

  end
end
