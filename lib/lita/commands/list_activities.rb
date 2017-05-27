module Lita
  module Commands

    class ListActivities

      def name
        'list-activities'
      end

      def duration_minutes
        30
      end

      def buffer_minutes
        30
      end

      def run(robot, target, gateway, window_start, window_end)
        activities = gateway.admin_activities(window_start, window_end)
        activities.sort_by(&:time).map(&:to_msg).each_with_index do |message, index|
          robot.send_message(target, message)
          sleep(1) # TODO ergh. required to stop slack disconnecting us for high sending rates
        end
      end
    end
  end
end
