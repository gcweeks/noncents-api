class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :vice

  # Validations
  validates :account_id, presence: true
  validates :amount, presence: true
  validates :category_id, presence: true
  validates :date, presence: true
  validates :name, presence: true
  validates :plaid_id, presence: true
  validates :user, presence: true
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
    transaction
  end

  def invest!(amount)
    self.invested = true
    self.amount_invested += amount
    save!
  end

  def archive!
    # Flag as archived. If older than some threshold, delete instead of
    # archiving

    # Currently don't delete any Transactions
    # current_month = Date.current.beginning_of_month
    if false #self.date.beginning_of_month < current_month - 1.month
      # Delete if older than 1 month
      self.destroy
    elsif !self.archived
      # Flag as archived
      self.archived = true
      self.save!
    end
  end
end
