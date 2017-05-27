module Lita
  module Commands

    class EmptyGroups

      def name
        'empty-groups'
      end

      def run(robot, target, gateway)
        msg = EmptyGroupsMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = EmptyGroupsMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No groups found")
        end
      end
    end

  end
end
