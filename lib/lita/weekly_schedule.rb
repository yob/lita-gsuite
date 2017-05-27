module Lita
  class WeeklySchedule
    attr_reader :id, :room_name, :user_id, :day, :time, :cmd

    def initialize(id:, room_name:, user_id:, day:, time:, cmd:)
      @id = id
      @room_name, @user_id = room_name, user_id
      @day, @time = day.to_s.to_sym, time.to_s
      @cmd = cmd.new if cmd
    end

    def name
      @cmd.name
    end

    def run(*args)
      @cmd.run(*args)
    end

    def valid?
      room_name && user_id && valid_day? && valid_time? && valid_cmd?
    end

    def to_json
      {
        id: @id,
        day: @day,
        time: @time,
        cmd: @cmd.name,
        user_id: @user_id,
        room_name: @room_name,
      }.to_json
    end

    def human
      "Weekly (id: #{@id}): #{@day} #{@time} - #{@cmd.name}"
    end

    private

    def valid_day?
      [:monday, :tuesday, :wednesday, :thursday, :saturday, :sunday].include?(day)
    end

    def valid_time?
      time.match(/\A\d\d:\d\d\Z/)
    end

    def valid_cmd?
      cmd.respond_to?(:run)
    end
  end

end
