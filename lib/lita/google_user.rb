module Lita
  # A google apps user
  class GoogleUser
    attr_reader :id, :full_name, :email, :created_at, :last_login_at, :ou_path

    def self.from_api_user(user)
      GoogleUser.new(
        id: user.id,
        full_name: user.name.full_name,
        email: user.primary_email,
        suspended: user.suspended,
        created_at: user.creation_time,
        last_login_at: user.last_login_time,
        ou_path: user.org_unit_path,
        admin: user.is_admin,
        delegated_admin: user.is_delegated_admin,
        two_factor_enabled: user.is_enrolled_in2_sv,
        two_factor_enforced: user.is_enforced_in2_sv,
      )
    end

    def initialize(id:, full_name:, email:, suspended:, created_at:, last_login_at:, ou_path:, admin:, delegated_admin:, two_factor_enabled:, two_factor_enforced:)
      @id = id
      @email = email
      @full_name = full_name
      @suspended = suspended
      @created_at = created_at
      @last_login_at = last_login_at
      @ou_path = ou_path
      @admin = admin
      @delegated_admin = delegated_admin
      @two_factor_enabled = two_factor_enabled
      @two_factor_enforced = two_factor_enforced
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

    def two_factor_enabled?
      @two_factor_enabled
    end

    def two_factor_enforced?
      @two_factor_enforced
    end

  end
end
