module Lita
  class WindowSchedule
    attr_reader :id, :room_name, :user_id, :cmd

    def initialize(id:, room_name:, user_id:, cmd:)
      @id = id
      @room_name, @user_id = room_name, user_id
      @cmd = cmd.new if cmd
    end

    def duration_minutes
      @cmd.duration_minutes
    end

    def buffer_minutes
      @cmd.buffer_minutes
    end

    def name
      @cmd.name
    end

    def run(*args)
      @cmd.run(*args)
    end

    def human
      "Sliding Window (id: #{@id}): #{@cmd.name}"
    end

    def valid?
      room_name && user_id && valid_cmd?
    end

    def to_json
      {
        id: @id,
        cmd: @cmd.name,
        user_id: @user_id,
        room_name: @room_name,
      }.to_json
    end

    private

    def valid_cmd?
      cmd.respond_to?(:run)
    end
  end
end
