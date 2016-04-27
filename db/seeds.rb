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
user.create_fund
user.generate_token
user.save!
# Log user token for quicker testing
p user.token

vices = []
vice1 = Vice.find_by(name: "CoffeeShops")
vices.push vice1
vice2 = Vice.find_by(name: "Electronics")
vices.push vice2
user.vices << vices

bank = user.banks.new(name: 'wells', access_token: 'test_wells')
bank.save!

account1 = user.accounts.new(
  plaid_id: 'QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK',
  name: 'Plaid Savings',
  institution: 'fake_institution',
  account_num: 0,
  routing_num: 0,
  account_type: 'depository',
  account_subtype: 'savings')
account1.save!
account2 = user.accounts.new(
  plaid_id: 'nban4wnPKEtnmEpaKzbYFYQvA7D7pnCaeDBMy',
  name: 'Plaid Checking',
  institution: 'fake_institution',
  account_num: 0,
  routing_num: 0,
  account_type: 'depository',
  account_subtype: 'checking')
account2.save!
account3 = user.accounts.new(
  plaid_id: 'XARE85EJqKsjxLp6XR8ocg8VakrkXpTXmRdOo',
  name: 'Plaid Premier Checking',
  institution: 'fake_institution',
  account_num: 0,
  routing_num: 0,
  account_type: 'depository',
  account_subtype: 'checking')
account3.save!
account4 = user.accounts.new(
  plaid_id: 'pJPM4LMBNQFrOwp0jqEyTwyxJQrQbgU6kq37k',
  name: 'Plaid Credit Card',
  institution: 'fake_institution',
  account_num: 0,
  routing_num: 0,
  account_type: 'credit')
account4.save!

transaction = user.transactions.new(
  plaid_id: 'KdDjmojBERUKx3JkDdO5IaRJdZeZKNuK4bnKJ1',
  date: DateTime.current-3.days,
  amount: '2307.15',
  name: 'Apple Store',
  category_id: '19013000')
transaction.account = account1
transaction.vice = vice2
transaction.save!

transaction = user.transactions.new(
  plaid_id: 'DAE3Yo3wXgskjXV1JqBDIrDBVvjMLDCQ4rMQdR',
  date: DateTime.current-4.days,
  amount: '3.19',
  name: 'Gregorys Coffee',
  category_id: '13005043')
transaction.account = account2
transaction.vice = vice1
transaction.save!

transaction = user.transactions.new(
  plaid_id: 'moPE4dE1yMHJX5pmRzwrcvpQqPdDnZHEKPREYL',
  date: DateTime.current-5.days,
  amount: '7.23',
  name: 'Krankies Coffee',
  category_id: '13005043')
transaction.account = account1
transaction.vice = vice1
transaction.save!

transaction = user.transactions.new(
  plaid_id: 'JmN0JX0q5EcaQJM9ZbOwUYyyp607m4u3PR63Vn',
  date: DateTime.current-6.days,
  amount: '5.32',
  name: 'Octane Coffee Bar and Lounge',
  category_id: '13005043')
transaction.account = account1
transaction.vice = vice1
transaction.save!
