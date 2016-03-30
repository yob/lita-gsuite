module Lita
  class MaxWeeksSuspendedMessage
    def initialize(gateway, max_weeks_suspended)
      @gateway = gateway
      @max_weeks_suspended = max_weeks_suspended.to_i
    end

    def to_msg
      return nil if long_term_suspended_users.empty?

      msg = "The following users are suspended, and have not logged in for #{@max_weeks_suspended} weeks. "
      msg += "If appropriate, consider deleting their accounts:\n"
      msg += long_term_suspended_users.map { |user|
        "- #{user.ou_path}/#{user.email}"
      }.join("\n")
    end

    private

    def long_term_suspended_users
      @users ||= @gateway.users.select { |user|
        user.suspended?
      }.select { |user|
        user.last_login_at < max_weeks_suspended_ago
      }
    end

    def max_weeks_suspended_ago
      @max_weeks_suspended_ago ||= Time.now.utc - weeks_in_seconds(@max_weeks_suspended)
    end

    def weeks_in_seconds(weeks)
      60 * 60 * 24 * 7 * weeks.to_i
    end

  end
end
