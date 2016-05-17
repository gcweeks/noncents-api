class Transaction < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  belongs_to :vice

  # Validations
  validates :plaid_id, presence: true
  validates :date, presence: true
  validates :amount, presence: true
  validates :name, presence: true
  validates :category_id, presence: true
  validates :account_id, presence: true
  validates :vice, presence: true

  def as_json(options = {})
    json = super({
      except: [:vice_id]
    }.merge(options))
    json['vice'] = vice.name
    json
  end

  # Turn a Plaid transaction into a Transaction model
  def self.from_plaid(plaid_transaction)
    transaction = new
    transaction.plaid_id = plaid_transaction.id
    transaction.date = plaid_transaction.date
    transaction.amount = plaid_transaction.amount
    transaction.name = plaid_transaction.name
    transaction.category_id = plaid_transaction.category_id
    transaction.account_id = plaid_transaction.account_id
    transaction
  end

  def invest!(amount)
    self.invested = true
    self.amount_invested += amount
    save!
  end
end
