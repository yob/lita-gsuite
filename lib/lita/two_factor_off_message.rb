module Lita
  # List the users with an Organisational Unit that don't have two factor auth enabled
  class TwoFactorOffMessage
    def initialize(gateway, ou_path)
      @gateway = gateway
      @ou_path = ou_path
    end

    def to_msg
      if users_without_tfa.any?
        msg = "Users in #{@ou_path} with Two Factor Authentication disabled:\n\n"
        users_without_tfa.each do |user|
          msg += "- #{user.email}\n"
        end
        msg
      end
    end

    private

    def users_without_tfa
      @users_without_tfa ||= ou_users.reject { |user| user.two_factor_enabled? }
    end

    def ou_users
      active_users.select { |user| user.ou_path == @ou_path }
    end

    def active_users
      @active_user ||= @gateway.users.reject { |user|
        user.suspended?
      }
    end

  end
end

