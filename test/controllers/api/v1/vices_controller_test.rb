require 'test_helper'

class Api::V1::VicesControllerTest < ActionController::TestCase
  test 'should get vices' do
    get :index
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res.sort,
                 %w(Movies Shopping RideSharing
                    Experiences Electronics CoffeeShops Nightlife Travel
                    Restaurants PersonalCare FastFood).sort
  end
end
