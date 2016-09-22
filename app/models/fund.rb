class Fund < ApplicationRecord
  belongs_to :user

  validates :amount_invested, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :user, presence: true

  def as_json(options = {})
    json = super({
      except: [:user_id]
    }.merge(options))
    json
  end

  def deposit!(amount)
    return unless amount > 0.0
    self.amount_invested += amount
    # Artificially increase balance until real balance is pulled
    self.balance += amount
    save!
  end
end
