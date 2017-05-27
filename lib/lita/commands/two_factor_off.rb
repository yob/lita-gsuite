module Lita
  module Commands

    class TwoFactorOff

      def initialize(ou_path = "/")
        @ou_path = ou_path
      end

      def name
        'two-factor-off'
      end

      def run(robot, target, gateway)
        msg = TwoFactorOffMessage.new(gateway, @ou_path).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = TwoFactorOffMessage.new(gateway, @ou_path).to_msg
        if msg
          robot.send_message(target, msg)
        else
          robot.send_message(target, "No users found")
        end
      end
    end
  end
end
