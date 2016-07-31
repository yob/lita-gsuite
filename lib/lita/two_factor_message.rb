module Lita
  class TwoFactorMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      msg = "Active users with Two Factor Authentication enabled:\n\n"
      orgunits.each do |ou|
        msg += ou_msg(ou)
      end
      msg + "- Overall #{count_with_tfa}/#{count_all} (#{percentage(count_with_tfa, count_all)}%)"
    end

    private

    def ou_msg(ou)
      with_tfa = count_ou_users_with_tfa(ou)
      all_users = count_ou_users(ou)
      "- #{ou.path} #{with_tfa}/#{all_users} (#{percentage(with_tfa, all_users)}%)\n"
    end

    def count_ou_users_with_tfa(ou)
      ou_users_with_tfa(ou).size
    end

    def ou_users_with_tfa(ou)
      ou_users(ou).select { |user|
        two_factor_user_emails.include?(user.email)
      }
    end

    def count_ou_users(ou)
      ou_users(ou).size
    end

    def ou_users(ou)
      active_users.select { |user|
        user.ou_path == ou.path
      }
    end

    def orgunits
      @orgunits ||= @gateway.organisational_units.sort_by(&:path)
    end

    def count_all
      active_user_emails.size
    end

    def count_with_tfa
      @count_with_tfa ||= two_factor_user_emails.size
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

    def active_user_emails
      active_users.map(&:email)
    end

    def two_factor_user_emails
      @tfa_user_emails ||= @gateway.two_factor_users.map(&:email).select { |email|
        active_user_emails.include?(email)
      }
    end

  end
end
