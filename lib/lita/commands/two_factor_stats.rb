module Lita
  module Commands
    class TwoFactorStats

      def name
        'two-factor-stats'
      end

      def run(robot, target, gateway)
        msg = TwoFactorMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = TwoFactorMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No stats found")
        end
      end
    end

  end
end
