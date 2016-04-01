module Lita

  # A user that has two factor authentication enabled
  class GoogleTwoFactorUser
    attr_reader :email

    def self.from_api(item)
      GoogleTwoFactorUser.new(
        email: item.entity.userEmail
      )
    end

    def initialize(email:)
      @email = email
    end

    def to_s
      @email
    end
  end
end
