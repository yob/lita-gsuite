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
        if msg.nil? && opts[:negative_ack]
          robot.send_message(target, "All users in #{@ou_path} have Two Factor Authentication enabled")
        end
      end
    end
  end
end
