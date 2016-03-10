require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'validations' do
    user = users(:cashmoney)
    user.generate_token
    new_user = User.new(fname: user.fname, lname: user.lname, dob: user.dob,
                        email: 'valid@email.com', password: 'password')

    # Token
    assert_not user.save, 'Saved User without token'
    new_user.generate_token
    assert new_user.save, 'Couldn\'t save valid User'

    # Password
    assert_not user.save, 'Saved User without password'
    password = 'cashmoney'
    user.password = password
    assert user.save, 'Couldn\'t save valid User'
    user.password = 'cash'
    assert_not user.save, 'Saved User with short password'
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
    new_user.email = user.email
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
    assert_equal user.invest_percent, 0, 'Invest percent not default \
      initialized to 0'
    percent = user.invest_percent
    user.invest_percent = nil
    assert_not user.save, 'Saved User without invest percent'
    user.invest_percent = 101
    assert_not user.save, 'Saved User with invalid invest percent (>100)'
    user.invest_percent = -1
    assert_not user.save, 'Saved User with invalid invest percent (<0)'
    user.invest_percent = percent

    # Optional number
    number = user.number
    user.number = nil
    assert user.save, 'Couldn\'t save valid User'
    user.number = number
  end
end
