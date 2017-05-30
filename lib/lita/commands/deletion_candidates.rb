module Lita
  module Commands

    class DeletionCandidates
      MAX_WEEKS_SUSPENDED = 26

      def name
        'deletion-candidates'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users found") if msg.nil? && opts[:negative_ack]
      end

      private

      def build_msg(gateway)
        users = long_term_suspended_users(gateway)
        if users.any?
          msg = "The following users are suspended, and have not logged in for #{MAX_WEEKS_SUSPENDED} weeks. "
          msg += "If appropriate, consider deleting their accounts:\n"
          msg += users.map { |user|
            "- #{user.ou_path}/#{user.email}"
          }.sort.join("\n")
        end
      end

      def long_term_suspended_users(gateway)
        timestamp = max_weeks_suspended_ago

        gateway.users.select { |user|
          user.suspended?
        }.select { |user|
          user.last_login_at < timestamp
        }
      end

      def max_weeks_suspended_ago
        (Time.now.utc - weeks_in_seconds(MAX_WEEKS_SUSPENDED)).to_datetime
      end

      def weeks_in_seconds(weeks)
        60 * 60 * 24 * 7 * weeks.to_i
      end
    end
  end
end
