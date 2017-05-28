module Lita
  module Commands
    class TwoFactorStats

      def name
        'two-factor-stats'
      end

      def run(robot, target, gateway, opts = {})
        msg = TwoFactorMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No stats found") if msg.nil? && opts[:negative_ack]
      end
    end
  end
end
