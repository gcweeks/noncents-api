class Fund < ActiveRecord::Base
  belongs_to :user

  # Validations
  validates :amount_invested, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :user, presence: true

  def deposit!(amount)
    return unless amount > 0.0
    self.amount_invested += amount
    save!
  end
end
