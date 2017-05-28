module Lita
  module Commands

    class ListAdmins

      def name
        'list-admins'
      end

      def run(robot, target, gateway, opts = {})
        msg = AdminListMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No admins found") if msg.nil? && opts[:negative_ack]
      end
    end

  end
end
