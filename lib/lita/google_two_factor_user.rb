module Lita

  # A user that has two factor authentication enabled
  class GoogleTwoFactorUser
    attr_reader :email

    def initialize(email:)
      @email = email
    end

    def to_s
      @email
    end
  end
end
