module Lita
  # A google OrganisationUnit, contains zero or more users
  class GoogleOrganisationUnit
    attr_reader :name, :path

    def self.from_api(item)
      GoogleOrganisationUnit.new(
        name: item.name, path: item.org_unit_path
      )
    end

    def initialize(name:, path:)
      @name, @path = name, path
    end
  end
end
