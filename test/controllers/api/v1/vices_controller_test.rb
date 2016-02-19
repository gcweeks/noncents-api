require 'test_helper'

class Api::V1::VicesControllerTest < ActionController::TestCase
  test 'should get vices' do
    get :index
    assert_response :success
    assert_equal JSON(@response.body),
                 %w(Movies Shopping RideSharing
                    Experiences Electronics CoffeeShops Nightlife Travel
                    Restaurants PersonalCare FastFood)
  end
end
