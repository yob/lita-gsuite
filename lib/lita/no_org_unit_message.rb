module Lita
  class NoOrgUnitMessage
    def initialize(gateway)
      @gateway = gateway
    end

    def to_msg
      return nil if no_org_unit_users.empty?

      msg = "The following users are not assigned to an organisational unit:\n"
      msg += no_org_unit_users.map { |user|
        "- #{user.email}"
      }.join("\n")
    end

    private

    def no_org_unit_users
      @users ||= @gateway.users.reject { |user|
        user.suspended?
      }.select { |user|
        user.ou_path == "/"
      }
    end

  end
end
