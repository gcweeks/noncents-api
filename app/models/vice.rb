class Vice < ApplicationRecord
  has_many :user_vices
  has_many :users, through: :user_vices

  validates :name, presence: true
end
