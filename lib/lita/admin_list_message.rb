module Lita
  class AdminListMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      return nil if admins.empty?

      msg = "The following accounts have administrative privileges:\n"
      msg += admins.map { |user|
        "- #{user.ou_path}/#{user.email} (2fa enabled: #{tfa?(user.email)})"
      }.join("\n")
    end

    private

    def admins
      @users ||= @gateway.users.select { |user|
        user.admin? || user.delegated_admin?
      }
    end

    def tfa?(email)
      two_factor_user_emails.include?(email) ? "Y" : "N"
    end

    def two_factor_user_emails
      @tfa_user_emails ||= @gateway.two_factor_users.map(&:email)
    end

  end
end
