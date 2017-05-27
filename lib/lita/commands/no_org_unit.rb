module Lita
  module Commands
    class NoOrgUnit

      def name
        'no-org-unit'
      end

      def run(robot, target, gateway)
        msg = NoOrgUnitMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = NoOrgUnitMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No users are missing an org unit")
        end
      end
    end

  end
end
