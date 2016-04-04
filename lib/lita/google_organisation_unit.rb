module Lita
  # A google OrganisationUnit, contains zero or more users
  class GoogleOrganisationUnit
    attr_reader :name, :path

    def self.from_api(item)
      GoogleOrganisationUnit.new(
        name: item.name, path: item.orgUnitPath
      )
    end

    def initialize(name:, path:)
      @name, @path = name, path
    end
  end
end
