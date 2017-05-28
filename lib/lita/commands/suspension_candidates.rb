module Lita
  module Commands
    class SuspensionCandidates
      MAX_WEEKS_WITHOUT_LOGIN = 8

      def name
        'suspension-candidates'
      end

      def run(robot, target, gateway, opts = {})
        msg = MaxWeeksWithoutLoginMessage.new(gateway, MAX_WEEKS_WITHOUT_LOGIN).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users found") if msg.nil? && opts[:negative_ack]
      end

    end
  end
end
