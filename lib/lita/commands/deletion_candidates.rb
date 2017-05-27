module Lita
  module Commands

    class DeletionCandidates
      MAX_WEEKS_SUSPENDED = 26

      def name
        'deletion-candidates'
      end

      def run(robot, target, gateway)
        return if @max_weeks_suspended < 1

        msg = MaxWeeksSuspendedMessage.new(gateway, MAX_WEEKS_SUSPENDED).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = MaxWeeksSuspendedMessage.new(gateway, MAX_WEEKS_SUSPENDED).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users found")
        end
      end
    end
  end
end
