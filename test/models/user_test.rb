require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)

    # Token
    assert_not user.save, 'Saved User without token'
    user.generate_token

    # Fund
    assert_not user.save, 'Saved User without fund'
    user.create_fund

    # Password
    assert_not user.save, 'Saved User without password'
    password = 'Ca5hM0n3y'
    user.password = password
    assert user.save, "Couldn't save valid User"
    user = User.find_by(id: user.id) # Refresh User
    user.password = 'cash'
    assert_not user.save, 'Saved User with short password'
    user.password = 'cashmoney1'
    assert_not user.save, 'Saved User without capital letter in password'
    user.password = 'Cashmoney'
    assert_not user.save, 'Saved User without number in password'
    user.password = password

    # Email
    email = user.email
    user.email = nil
    assert_not user.save, 'Saved User without email'
    user.email = '@gmail.com'
    assert_not user.save, 'Saved User with improper email format 1'
    user.email = 'cashmoney@gmail.'
    assert_not user.save, 'Saved User with improper email format 2'
    user.email = email
    new_user = User.new(fname: user.fname, lname: user.lname, dob: user.dob,
                        email: user.email, password: 'password')
    new_user.generate_token
    assert_not new_user.save, 'Saved new User with duplicate email'

    # Name
    fname = user.fname
    user.fname = ''
    assert_not user.save, 'Saved User without first name'
    user.fname = fname
    lname = user.lname
    user.lname = nil
    assert_not user.save, 'Saved User without last name'
    user.lname = lname

    # DOB
    dob = user.dob
    user.dob = nil
    assert_not user.save, 'Saved User without dob'
    user.dob = dob

    # Invest percent
    percent = user.invest_percent
    user.invest_percent = nil
    assert_not user.save, 'Saved User without invest percent'
    user.invest_percent = 101
    assert_not user.save, 'Saved User with invalid invest percent (>100)'
    user.invest_percent = -1
    assert_not user.save, 'Saved User with invalid invest percent (<0)'
    user.invest_percent = percent

    # Goal
    user.goal = nil
    assert_not user.save, 'Saved User without goal'
    user.goal = 0
    assert_not user.save, 'Saved User with out-of-range goal'
    user.goal = -10
    assert_not user.save, 'Saved User with out-of-range goal'
    user.goal = 6000
    assert_not user.save, 'Saved User with out-of-range goal'
    user.goal = 420
    assert user.save, "Couldn't save valid User"
    user = User.find_by(id: user.id) # Refresh User

    # Optional number
    number = user.number
    user.number = nil
    assert user.save, "Couldn't save valid User"
    user.number = number
    user.save!
    # user = User.find_by(id: user.id) # Refresh User
  end
end
