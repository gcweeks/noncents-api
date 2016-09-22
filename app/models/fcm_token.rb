class FcmToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true
  validates :user, presence: true
end
