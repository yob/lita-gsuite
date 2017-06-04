module Lita
  module Commands
    class NoOrgUnit

      def name
        'no-org-unit'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users are missing an org unit") if msg.nil? && opts[:negative_ack]
      end

      private

      def build_msg(gateway)
        users = no_org_unit_users(gateway)

        if users.any?
          msg = "The following users are not assigned to an organisational unit:\n"
          msg += users.sort_by(&:path).map { |user|
            "- #{user.email}"
          }.join("\n")
        end
      end

      def no_org_unit_users(gateway)
        gateway.users.reject { |user|
          user.suspended?
        }.select { |user|
          user.ou_path == "/"
        }
      end

    end
  end
end
