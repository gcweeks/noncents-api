# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

vice_names = %w(Nightlife Restaurants Shopping FastFood CoffeeShops Travel
                Experiences Electronics PersonalCare Movies RideSharing)
vice_names.each do |name|
  Vice.create(name: name)
end

user = User.new(fname: 'Cash', lname: 'Money', dob: '1990-01-20',
                number: '+15555552016', invest_percent: 10,
                password: 'Ca5hM0n3y', email: 'cashmoney@gmail.com')
user.create_fund!
user.generate_token
user.save!
# Log user token for quicker testing
p user.token

vices = []
vice = Vice.find_by(name: "CoffeeShops")
vices.push vice
vice = Vice.find_by(name: "Electronics")
vices.push vice
user.vices << vices

bank = user.banks.new(name: 'wells', access_token: 'test_wells')
bank.save!

account = user.accounts.new(plaid_id: 'QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK',
                  name: 'Plaid Savings',
                  institution: 'fake_institution',
                  account_num: 0,
                  routing_num: 0,
                  account_type: 'depository',
                  account_subtype: 'savings')
account.save!
account = user.accounts.new(plaid_id: 'nban4wnPKEtnmEpaKzbYFYQvA7D7pnCaeDBMy',
                  name: 'Plaid Checking',
                  institution: 'fake_institution',
                  account_num: 0,
                  routing_num: 0,
                  account_type: 'depository',
                  account_subtype: 'checking')
account.save!
account = user.accounts.new(plaid_id: 'XARE85EJqKsjxLp6XR8ocg8VakrkXpTXmRdOo',
                  name: 'Plaid Premier Checking',
                  institution: 'fake_institution',
                  account_num: 0,
                  routing_num: 0,
                  account_type: 'depository',
                  account_subtype: 'checking')
account.save!
account = user.accounts.new(plaid_id: 'pJPM4LMBNQFrOwp0jqEyTwyxJQrQbgU6kq37k',
                  name: 'Plaid Credit Card',
                  institution: 'fake_institution',
                  account_num: 0,
                  routing_num: 0,
                  account_type: 'credit')
account.save!
