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
    get :auth, user: { email: 'no@such.email', password: 'incorrect' }
    assert_response :not_found
    get :auth, user: { email: @user.email, password: @user.password }
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal @user.token, res['token']
  end

  test 'should signup' do
    # Missing email
    post :signup, user: { password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid email
    post :signup, user: { email: 'bad@email',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Existing email
    post :signup, user: { email: @user.email,
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing password
    post :signup, user: { email: 'new@email.com',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid password
    post :signup, user: { email: 'new@email.com',
                          password: 'short',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing fname
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing lname
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: -1,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: 101,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing dob
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent
                        }
    assert_response :unprocessable_entity
    # Valid User
    post :signup, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :success

    # Check Token
    res = JSON.parse(@response.body)
    assert_equal 24, res['token'].length
  end

  test 'should get version' do
    get :version_ios
    assert_response :success
    res = JSON.parse(@response.body)
    assert_match(/^[0-9]*\.[0-9]*\.[0-9]*$/, res['version'])
  end
  # @request.headers['Authorization'] = @user.token
end
