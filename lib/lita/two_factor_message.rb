module Lita
  class TwoFactorMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      "#{count_with_tfa}/#{count_all} (#{percentage}%) active users have Two Factor Authentication enabled"
    end

    private

    def count_all
      active_user_emails.size
    end

    def count_with_tfa
      @count_with_tfa ||= two_factor_user_emails.size
    end

    def percentage
      (
        BigDecimal.new(count_with_tfa) / BigDecimal.new(count_all) * 100
      ).round(2).to_s("F")
    end

    def active_user_emails
      @active_user_emails ||= @gateway.users.reject { |user|
        user.suspended?
      }.map(&:email)
    end

    def two_factor_user_emails
      @tfa_user_emails = @gateway.two_factor_users.map(&:email).select { |email|
        active_user_emails.include?(email)
      }
    end

  end
end
