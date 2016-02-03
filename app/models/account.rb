class Account < ActiveRecord::Base
  belongs_to :user

  validates :plaid_id, presence: true
  validates :name, presence: true
  validates :account_type, presence: true
  validates :institution, presence: true
end
