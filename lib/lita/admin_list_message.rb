module Lita
  class AdminListMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      return nil if admins.empty?

      msg = "The following accounts have administrative privileges:\n"
      msg += admins.map { |user|
        "- #{user.ou_path}/#{user.email} (2fa enabled: #{tfa?(user)})"
      }.join("\n")
    end

    private

    def admins
      @users ||= (@gateway.delegated_admins + @gateway.super_admins).uniq.sort_by { |user|
        [user.ou_path, user.email]
      }
    end

    def tfa?(user)
      user.two_factor_enabled? ? "Y" : "N"
    end

  end
end
