require 'test_helper'

class V1::VicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/vices/'
  end

  test 'should get vices' do
  get '/'
  assert_response :success
  res = JSON.parse(@response.body)
  assert_equal res.sort,
               %w(Movies Shopping RideSharing
                  Experiences Electronics CoffeeShops Nightlife Travel
                  Restaurants PersonalCare FastFood).sort
  end
end
