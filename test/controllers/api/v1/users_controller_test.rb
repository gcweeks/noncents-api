require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'cashmoney'
    @user.generate_token!
    @user.save!
  end

  test 'should get me' do
    @request.headers['Authorization'] = @user.token
    get :get_me
    assert_response :success
  end

  test 'should update me' do
    @request.headers['Authorization'] = @user.token
    fname = 'Test'
    put :update_me, user: { fname: fname }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal res['fname'], fname
  end
end
