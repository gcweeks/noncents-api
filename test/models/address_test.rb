require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  test 'validations' do
    address = addresses(:test_address)
    assert address.save, 'Couldn\'t save valid Address'

    # Line 1
    line1 = address.line1
    address.line1 = nil
    assert_not address.save, 'Saved Address without line1'
    address.line1 = line1

    # Line 2 is optional
    line2 = address.line2
    address.line2 = nil
    assert address.save, 'Couldn\'t save valid Address'
    address.line2 = line2

    # City
    city = address.city
    address.city = nil
    assert_not address.save, 'Saved Address without city'
    address.city = city

    # State
    state = address.state
    address.state = nil
    assert_not address.save, 'Saved Address without state'
    address.state = state

    # Zip
    zip = address.zip
    address.zip = nil
    assert_not address.save, 'Saved Address without zip'
    address.zip = zip
  end
end
