module Lita
  module Commands

    class TwoFactorOff

      def initialize(ou_path = "/")
        @ou_path = ou_path
      end

      def name
        'two-factor-off'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        if msg.nil? && opts[:negative_ack]
          robot.send_message(target, "All users in #{@ou_path} have Two Factor Authentication enabled")
        end
      end

      private

      def build_msg(gateway)
        users = active_users_without_tfa(gateway)

        if users.any?
          msg = "Users in #{@ou_path} with Two Factor Authentication disabled:\n\n"
          users.each do |user|
            msg += "- #{user.email}\n"
          end
          msg
        end
      end

      def active_users_without_tfa(gateway)
        gateway.users.reject { |user|
          user.suspended?
        }.reject { |user|
          user.two_factor_enabled?
        }.select { |user|
          user.ou_path == @ou_path
        }.sort_by { |user|
          user.path
        }
      end
    end
  end
end
