require 'test_helper'

class ViceTest < ActiveSupport::TestCase
  test 'validations' do
    vice = vices(:nightlife)
    assert vice.save, 'Couldn\'t save valid Account'

    # Name
    name = vice.name
    vice.name = nil
    assert_not vice.save, 'Saved Vice without name'
    vice.name = name
  end
end
