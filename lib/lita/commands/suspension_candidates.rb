module Lita
  module Commands
    class SuspensionCandidates
      MAX_WEEKS_WITHOUT_LOGIN = 8

      def name
        'suspension-candidates'
      end

      def run(robot, target, gateway)
        return if @max_weeks_without_login < 1

        msg = MaxWeeksWithoutLoginMessage.new(gateway, MAX_WEEKS_WITHOUT_LOGIN).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = MaxWeeksWithoutLoginMessage.new(gateway, MAX_WEEKS_WITHOUT_LOGIN).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users found")
        end
      end
    end

  end
end
