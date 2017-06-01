require 'bigdecimal'

module Lita
  class TwoFactorMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      users = active_users
      if users.any?
        users_with_tfa = users.select { |user| user.two_factor_enabled? }
        ou_paths = users.group_by(&:ou_path).keys.sort

        msg = "Active users with Two Factor Authentication enabled:\n\n"
        ou_paths.each do |ou_path|
          msg += ou_msg(ou_path, users) + "\n"
        end
        msg + "- Overall #{users_with_tfa.size}/#{users.size} (#{percentage(users_with_tfa.size, users.size)}%)"
      end
    end

    private

    def ou_msg(ou_path, users)
      ou_users = users.select { |user| user.ou_path == ou_path }
      with_tfa = ou_users.select { |user| user.two_factor_enabled? }
      "- #{ou_path} #{with_tfa.size}/#{ou_users.size} (#{percentage(with_tfa.size, ou_users.size)}%)"
    end

    def percentage(num, denom)
      if denom == 0
        result = BigDecimal.new(0)
      else
        result = BigDecimal.new(num) / BigDecimal.new(denom) * 100
      end
      result.round(2).to_s("F")
    end

    def active_users
      @active_user ||= @gateway.users.reject { |user|
        user.suspended?
      }
    end

  end
end
