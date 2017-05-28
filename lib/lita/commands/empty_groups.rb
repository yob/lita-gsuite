module Lita
  module Commands

    class EmptyGroups

      def name
        'empty-groups'
      end

      def run(robot, target, gateway, opts = {})
        msg = EmptyGroupsMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No groups found") if msg.nil? && opts[:negative_ack]
      end
    end

  end
end
