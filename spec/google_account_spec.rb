
describe Lita::GoogleAccount do
  let(:account) {
    Lita::GoogleAccount.new(
      id: "123",
      alternate_email: "user@foo.com",
      primary_domain: "example.com",
      created_at: DateTime.parse("2017-06-07 12:34:56"),
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
  describe "#address" do
    it "returns the address as a single string" do
      expect(account.address).to eq("1 Swanston St, Melbourne, 3000, AU")
    end
  end

  describe "#to_s" do
    it "returns a string" do
      expect(account.to_s).to eq("Account 123")
    end
  end
end

