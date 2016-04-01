module Lita
  class EmptyGroupsMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      return nil if empty_groups.empty?

      msg = "The following groups have no members, which may result in undelivered email.\n"
      msg += empty_groups.map { |group|
        "- #{group.email}"
      }.join("\n")
    end

    private

    def empty_groups
      @users ||= @gateway.groups.select { |group|
        group.member_count == 0
      }
    end

  end
end
