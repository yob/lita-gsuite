module Lita
  module Commands

    class ListAdmins

      def name
        'list-admins'
      end

      def run(robot, target, gateway)
        msg = AdminListMessage.new(gateway).to_msg
        robot.send_message(target, msg) if msg
      end

      def run_manual(robot, target, gateway)
        msg = AdminListMessage.new(gateway).to_msg
        if msg
          robot.send_message(target, msg) if msg
        else
          robot.send_message(target, "No admins found")
        end
      end
    end

  end
end
