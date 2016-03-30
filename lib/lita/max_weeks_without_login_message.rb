module Lita
  class MaxWeeksWithoutLoginMessage
    def initialize(gateway, max_weeks_without_login)
      @gateway = gateway
      @max_weeks_without_login = max_weeks_without_login.to_i
    end

    def to_msg
      return nil if active_users_with_no_recent_login.empty?

      msg = "The following users have active accounts, but have not logged in for #{@max_weeks_without_login} weeks. "
      msg += "If appropriate, consider suspending or deleting their accounts:\n"
      msg += active_users_with_no_recent_login.map { |user|
        "- #{user.ou_path}/#{user.email}"
      }.join("\n")
    end

    private

    def active_users_with_no_recent_login
      @users ||= @gateway.users.reject { |user|
        user.suspended?
      }.select { |user|
        user.last_login_at < max_weeks_without_login_ago && user.created_at < max_weeks_without_login_ago
      }
    end

    def max_weeks_without_login_ago
      @max_weeks_without_login_ago ||= Time.now.utc - weeks_in_seconds(@max_weeks_without_login)
    end

    def weeks_in_seconds(weeks)
      60 * 60 * 24 * 7 * weeks.to_i
    end

  end
end
