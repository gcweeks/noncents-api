require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:cashmoney)
    @user.password = 'cashmoney'
    @user.generate_token!
    @user.save!
  end

  test 'should create' do
    # Missing email
    post :create, user: { password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid email
    post :create, user: { email: 'bad@email',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Existing email
    post :create, user: { email: @user.email,
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing password
    post :create, user: { email: 'new@email.com',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid password
    post :create, user: { email: 'new@email.com',
                          password: 'short',
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing fname
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing lname
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          invest_percent: @user.invest_percent,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: -1,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Invalid invest_percent
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: 101,
                          dob: @user.dob
                        }
    assert_response :unprocessable_entity
    # Missing dob
    post :create, user: { email: 'new@email.com',
                          password: @user.password,
                          fname: @user.fname,
                          lname: @user.lname,
                          invest_percent: @user.invest_percent
                        }
    assert_response :unprocessable_entity
    # Valid User
    post :create, user: { email: 'new@email.com',
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

  test 'should set vices' do
    @request.headers['Authorization'] = @user.token

    # Nil Vice
    post :set_vices
    assert_response :bad_request

    # Bad format
    vices = 'badformat'
    post :set_vices, vices: vices
    assert_response :bad_request

    # Non-existent Vice
    vices = %w(IDontExist)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity
    vices = %w(Travel IDontExist)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity
    vices = %w(IDontExist Travel)
    post :set_vices, vices: vices
    assert_response :unprocessable_entity

    # Correct Vices
    vices = %w(Travel Nightlife)
    post :set_vices, vices: vices
    assert_response :success
    assert_equal JSON(@response.body)['vices'], vices

    # No Vice
    vices = %w(None)
    post :set_vices, vices: vices
    assert_response :success
    assert_equal JSON(@response.body)['vices'], []
  end

  test 'should connect to plaid' do
    # get :account_connect
    # get :account_connect, var: var
  end

  test 'should mfa with plaid' do
    # get :account_mfa
    # get :account_mfa, var: var
  end

  test 'should remove accounts' do
    # put :remove_accounts
    # put :remove_accounts, var: var
  end
end
