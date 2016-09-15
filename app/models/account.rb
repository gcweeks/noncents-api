class Account < ApplicationRecord
  belongs_to :user
  belongs_to :bank
  has_many :transactions

  validates :plaid_id, presence: true
  validates :name, presence: true
  validates :account_type, presence: true
  validates :institution, presence: true
  validates :bank, presence: true
end
