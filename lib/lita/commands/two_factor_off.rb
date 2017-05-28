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
        msg = TwoFactorOffMessage.new(gateway, @ou_path).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users found") if msg.nil? && opts[:negative_ack]
      end
    end
  end
end
