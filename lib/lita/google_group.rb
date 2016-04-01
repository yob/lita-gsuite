module Lita
  # A google email group
  class GoogleGroup
    attr_reader :id, :email, :name, :member_count, :description

    def self.from_api(group)
      GoogleGroup.new(
        id: group.id,
        email: group.email,
        name: group.name,
        description: group.description,
        member_count: group.directMembersCount,
      )
    end

    def initialize(id:, email:, name:, member_count:, description:)
      @id, @email, @name, @description = id, email, name, description
      @member_count = member_count.to_i
    end

    def ==(other)
      @id == other.id && @email == other.email
    end

    def to_s
      @email
    end
  end
end
