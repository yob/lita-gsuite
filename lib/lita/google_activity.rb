module Lita
  class GoogleActivity
    attr_reader :time, :actor, :ip, :name, :params

    def initialize(time:, actor:, ip:, name:, params:)
      @time = time
      @actor = actor
      @ip = ip
      @name = name
      @params = params
    end

    def to_s
      @actor
    end

    def to_msg
      "#{@time.iso8601} #{@actor} #{@name}: #{@params.inspect}"
    end
  end
end
