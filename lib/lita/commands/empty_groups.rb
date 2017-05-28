module Lita
  module Commands

    class EmptyGroups

      def name
        'empty-groups'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg) if msg
        robot.send_message(target, "No groups found") if msg.nil? && opts[:negative_ack]
      end

      private

      def build_msg(gateway)
        groups = empty_groups(gateway)

        if groups.any?
          msg = "The following groups have no members, which may result in undelivered email.\n"
          msg += groups.map { |group|
            "- #{group.email}"
          }.join("\n")
        end
      end

      def empty_groups(gateway)
        gateway.groups.select { |group|
          group.member_count == 0
        }
      end
    end
  end
end
