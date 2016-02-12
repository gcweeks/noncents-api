Plaid.config do |p|
  p.customer_id = '5672296b795b36cc730ba6b5'
  p.secret = 'c0704f2af851cd5996579b70327700'
  p.environment_location = 'https://tartan.plaid.com/'
  # p.environment_location = 'https://api.plaid.com/'
end

## Some Plaid notes:
#
#
## Authenticate user
# user = Plaid.add_user('auth', 'plaid_test', 'plaid_good', 'wells')
#
#
## Get existing user based on plaid access token
## Notice I can change 'auth' to 'connect'
# user_new = Plaid.set_user(user.access_token, ['connect'])
#
#
#
## Models:
## User:
# accounts: [Account]
# transactions(AUTH): []
# transactions(CONNECT): [Transaction]
# access_token: String ("test_wells")
# type: ?
# permissions: [String] (['auth'])
# api_res: String ("success")
# pending_mfa_questions: {?}
# info: {?}
# information: ?
#
#
## Account
# id: String
# name: String
# type: String ("depository")
# meta: {
#   name: String (same as above?)
#   number: String (last 4 digits)
# }
# institution_type: String ("fake_institution")
# available_balance: Decimal (1234.56)
# current_balance: Decimal (1234.56)
# subtype: String ("savings")
# numbers(AUTH): {
#   routing: Integer (021000021)
#   account: Integer (9900009606)
#   wireRouting: Integer (021000021)
# }
# numbers(CONNECT):"Upgrade user to access routing information for this account"
#
#
## Transaction
# id: String
# account: String
# date: String ("2014-07-21")
# amount: Decimal (2307.15)
# name: String ("ATM Withdrawal")
# location: {
#   "city": String ("San Francisco")
#   "state": String ("CA")
# },
# pending: Bool
# pending_transaction: ?
# score: {
#   location: {
#     city: Integer,
#     state: Integer
#   },
#   name: Integer
# },
# cat: {
#   type: {
#     primary: String ("special")
#   },
#   hierarchy: [Transfer, Withdrawal, ATM],
#   id: String ("21012002")
# },
# type: {
#   primary: String ("special")
# },
# category: [Transfer, Withdrawal, ATM],
# category_id: String ("21012002")
# meta: {
#   location: {
#     city: String ("San Francisco")
#     state: String ("CA")
#   }
# }
