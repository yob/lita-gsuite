module Lita
  module Commands

    class ListAdmins

      def name
        'list-admins'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No admins found") if msg.nil? && opts[:negative_ack]
      end

      private

      def build_msg(gateway)
        users = all_admins(gateway)

        if users.any?
          msg = "The following accounts have administrative privileges:\n"
          msg += users.map { |user|
            "- #{user.ou_path}/#{user.email} (2fa enabled: #{tfa?(user)})"
          }.join("\n")
        end
      end

      def all_admins(gateway)
        (gateway.delegated_admins + gateway.super_admins).uniq.sort_by { |user|
          [user.ou_path, user.email]
        }
      end

      def tfa?(user)
        user.two_factor_enabled? ? "Y" : "N"
      end
    end

  end
end
