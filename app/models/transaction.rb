class Transaction < ActiveRecord::Base
  belongs_to :account

  # Turn a Plaid transaction into a Transaction model
  def self.create_from_plaid(plaid_transaction)
    transaction = create
    transaction.plaid_id = plaid_transaction.id
    transaction.date = Date.parse plaid_transaction.date
    transaction.amount = plaid_transaction.amount
    transaction.name = plaid_transaction.name
    transaction.category_id = plaid_transaction.category_id
    transaction.account_id = plaid_transaction.account
  end
end
