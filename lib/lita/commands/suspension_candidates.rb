module Lita
  module Commands
    class SuspensionCandidates
      MAX_WEEKS_WITHOUT_LOGIN = 8

      def name
        'suspension-candidates'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users found") if msg.nil? && opts[:negative_ack]
      end

      private

      def build_msg(gateway)
        users = active_users_with_no_recent_login(gateway)

        if users.any?
          msg = "The following users have active accounts, but have not logged in for #{MAX_WEEKS_WITHOUT_LOGIN} weeks. "
          msg += "If appropriate, consider suspending or deleting their accounts:\n"
          msg += users.map { |user|
            "- #{user.path}"
          }.sort.join("\n")
        end
      end

      def active_users_with_no_recent_login(gateway)
        timestamp = max_weeks_without_login_ago

        gateway.users.reject { |user|
          user.suspended?
        }.select { |user|
          user.last_login_at < timestamp && user.created_at < timestamp
        }
      end

      def max_weeks_without_login_ago
        (Time.now.utc - weeks_in_seconds(MAX_WEEKS_WITHOUT_LOGIN)).to_datetime
      end

      def weeks_in_seconds(weeks)
        60 * 60 * 24 * 7 * weeks.to_i
      end
    end
  end
end
