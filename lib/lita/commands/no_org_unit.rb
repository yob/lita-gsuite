module Lita
  module Commands
    class NoOrgUnit

      def name
        'no-org-unit'
      end

      def run(robot, target, gateway, opts = {})
        msg = NoOrgUnitMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No users are missing an org unit") if msg.nil? && opts[:negative_ack]
      end

    end
  end
end
