class DwollaDocument < ApplicationRecord
  belongs_to :user

  validates :dwolla_id, presence: true
  validates :user, presence: true
end
