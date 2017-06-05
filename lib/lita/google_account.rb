module Lita
  # A GSuite account
  class GoogleAccount
    attr_reader :id, :alternate_email, :created_at, :language, :phone_number
    attr_reader :primary_domain
    attr_reader :address_line1, :address_line2, :address_line3
    attr_reader :contact_name, :country_code, :organization_name, :postal_code, :region

    def self.from_api(account)
      GoogleAccount.new(
        id: account.id,
        alternate_email: account.alternate_email,
        created_at: account.customer_creation_time,
        primary_domain: account.customer_domain,
        language: account.language,
        phone_number: account.phone_number,
        address_line1: account.postal_address.address_line1,
        address_line2: account.postal_address.address_line2,
        address_line3: account.postal_address.address_line3,
        contact_name: account.postal_address.contact_name,
        country_code: account.postal_address.country_code,
        postal_code: account.postal_address.postal_code,
        region: account.postal_address.region
      )
    end

    def initialize(id:, alternate_email:, primary_domain:, created_at:, language:, phone_number:, address_line1: nil, address_line2: nil, address_line3: nil, contact_name: nil, country_code: nil, organization_name: nil, postal_code: nil, region: nil)
      @id, @alternate_email, @created_at = id, alternate_email, created_at
      @primary_domain = primary_domain
      @language, @phone_number = language, phone_number
      @address_line1, @address_line2, @address_line3 = address_line1, address_line2, address_line3
      @contact_name, @country_code, @organization_name = contact_name, country_code, organization_name
      @postal_code, @region = postal_code, region
    end

    def ==(other)
      @id == other.id
    end

    def address
      [
        address_line1,
        address_line2,
        address_line3,
        region,
        postal_code,
        country_code
      ].reject(&:nil?).join(", ")
    end

    def to_s
      "Account #{@id}"
    end
  end
end

