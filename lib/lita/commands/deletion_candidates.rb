module Lita
  module Commands

    class DeletionCandidates
      MAX_WEEKS_SUSPENDED = 26

      def name
        'deletion-candidates'
      end

      def run(robot, target, gateway, opts = {})
        msg = MaxWeeksSuspendedMessage.new(gateway, MAX_WEEKS_SUSPENDED).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users found") if msg.nil? && opts[:negative_ack]
      end

    end
  end
end
