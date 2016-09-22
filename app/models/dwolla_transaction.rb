class DwollaTransaction < ApplicationRecord
  belongs_to :user
  
  validates :dwolla_id, presence: true
  validates :balance, presence: true
  validates :source, presence: true
  validates :deposit, presence: true
  validates :amount, presence: true
end
