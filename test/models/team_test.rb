require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_teams
  end

end
