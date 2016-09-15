class Bank < ApplicationRecord
  belongs_to :user
  has_many :accounts

  validates :name, presence: true
  validates :access_token, presence: true
  validates :user, presence: true
end
