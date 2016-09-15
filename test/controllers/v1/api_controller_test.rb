require 'test_helper'

class V1::ApiControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! 'localhost:3000/v1/'
    @user = users(:cashmoney)
    @user.password = 'Ca5hM0n3y'
    @user.generate_token
    @user.create_fund
    @user.save!
    @headers = { 'Authorization' => @user.token }
  end

  test 'should get' do
    get '/'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'GET Request', res['body']
  end

  test 'should post' do
    post '/', params: { test1: 'test2' }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'POST Request: test1=test2', res['body']
  end

  test 'should auth' do
    get 'auth', params: { user: { email: @user.email, password: 'incorrect' } }
    assert_response :unauthorized
    get 'auth', params: { user: { email: 'does@not.exist', password: 'incorrect' } }
    assert_response :not_found
    get 'auth', params: { user: { email: @user.email, password: @user.password } }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
  end

  test 'should check email' do
    get 'check_email', params: { email: 'does@not.exist' }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'does not exist', res['email']

    get 'check_email', params: { email: @user.email }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal 'exists', res['email']
  end

  test 'should perform weekly deduct cron' do
    # Not implemented
  end

  test 'should perform transaction refresh cron' do
    # Not implemented
  end

  test 'should get version' do
    get 'version/ios'
    assert_response :success
    res = JSON.parse(@response.body)
    assert_match(/^[0-9]*\.[0-9]*\.[0-9]*$/, res['version'])
  end
end
