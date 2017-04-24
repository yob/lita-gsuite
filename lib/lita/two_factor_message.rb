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
      ou_users = active_users.select { |user| user.ou_path == ou.path }
      with_tfa = ou_users.select { |user| user.two_factor_enabled? }
      #with_tfa = count_ou_users_with_tfa(ou)
      #all_users = count_ou_users(ou)
      "- #{ou.path} #{with_tfa.size}/#{ou_users.size} (#{percentage(with_tfa.size, ou_users.size)}%)\n"
    end

    def orgunits
      @orgunits ||= @gateway.organisational_units.sort_by(&:path)
    end

    def count_all
      active_users.size
    end

    def count_with_tfa
      @count_with_tfa ||= active_users.select { |user| user.two_factor_enabled? }.size
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
