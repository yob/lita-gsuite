module Lita
  # A google apps user
  class GoogleUser
    attr_reader :id, :email, :last_login_at, :ou_path

    def initialize(id:, email:, suspended:, last_login_at:, ou_path:, admin:, delegated_admin:)
      @id = id
      @email = email
      @suspended = suspended
      @last_login_at = last_login_at
      @ou_path = ou_path
      @admin = admin
      @delegated_admin = delegated_admin
    end

    def to_s
      @email
    end

    def admin?
      @admin
    end

    def delegated_admin?
      @delegated_admin
    end

    def suspended?
      @suspended
    end

    def should_suspend?
      !suspended? && last_login_at < 2.months.ago
    end

    def should_delete?
      suspended? && last_login_at < 6.months.ago
    end
  end
end
