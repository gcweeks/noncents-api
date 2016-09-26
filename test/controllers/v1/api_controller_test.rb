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
    assert_equal AuthEvent.all.count, 0
    get 'auth', params: { user: { email: @user.email, password: 'incorrect' } }
    assert_response :unauthorized
    assert_equal AuthEvent.all.count, 1
    auth_event_1 = AuthEvent.all[0]
    assert_equal auth_event_1.user.id, @user.id
    assert_equal auth_event_1.success, false
    assert_equal auth_event_1.ip_address.to_s, @response.request.ip
    get 'auth', params: { user: { email: 'does@not.exist', password: 'incorrect' } }
    assert_response :not_found
    assert_equal AuthEvent.all.count, 1
    get 'auth', params: { user: { email: @user.email, password: @user.password } }
    assert_response :success
    assert_equal AuthEvent.all.count, 2
    auth_event_2 = AuthEvent.all.where.not(id: auth_event_1.id).first
    assert_equal auth_event_2.user.id, @user.id
    assert_equal auth_event_2.success, true
    assert_equal auth_event_2.ip_address.to_s, @response.request.ip
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
  end

  test 'should reset password' do
    # Requires email
    post 'reset_password'
    assert_response :bad_request

    post 'reset_password', params: { user: { email: @user.email } }
    assert_response :success
    @user.reload

    password = 'NewPa55word'

    # Assert old password still works and new one doesn't
    get 'auth', params: {
      user: {
        email: @user.email,
        password: @user.password
      }
    }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
    get 'auth', params: {
      user: {
        email: @user.email,
        password: password
      }
    }
    assert_response :unauthorized

    put 'update_password', params: {
      token: @user.reset_password_token,
      user: {
        email: @user.email,
        password: password
      }
    }
    assert_response :success

    # Assert new password works and old one doesn't
    get 'auth', params: {
      user: {
        email: @user.email,
        password: password
      }
    }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
    get 'auth', params: {
      user: {
        email: @user.email,
        password: @user.password
      }
    }
    assert_response :unauthorized
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
