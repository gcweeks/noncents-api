require 'test_helper'

class Api::V1::ApiControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'cashmoney'
    @user.generate_token!
    @user.save!
  end

  test 'should get' do
    get :request_get
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'GET Request', res['body']
  end

  test 'should post' do
    post :request_post, test1: 'test2'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'POST Request: test1=test2', res['body']
  end

  test 'should auth' do
    get :auth, user: { email: @user.email, password: 'incorrect' }
    assert_response :unauthorized
    get :auth, user: { email: 'does@not.exist', password: 'incorrect' }
    assert_response :not_found
    get :auth, user: { email: @user.email, password: @user.password }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
  end

  test 'should check email' do
    get :check_email, email: 'does@not.exist'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'does not exist', res['email']

    get :check_email, email: @user.email
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'exists', res['email']
  end

  test 'should get version' do
    get :version_ios
    assert_response :success
    res = JSON.parse(@response.body)
    assert_match(/^[0-9]*\.[0-9]*\.[0-9]*$/, res['version'])
  end
  # @request.headers['Authorization'] = @user.token
end
