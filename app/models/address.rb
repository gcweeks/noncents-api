class Address < ApplicationRecord
  belongs_to :user

  validates :line1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip, presence: true
end
