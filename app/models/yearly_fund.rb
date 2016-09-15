class YearlyFund < ApplicationRecord
  belongs_to :user

  # Validations
  validates :amount_invested, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :year, presence: true, numericality: { greater_than_or_equal_to: 2016 }
  validates :user, presence: true

  def deposit!(amount)
    return unless amount > 0.0
    self.amount_invested += amount
    # Artificially increase balance until real balance is pulled
    self.balance += amount
    save!
  end
end
