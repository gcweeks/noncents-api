class Bank < ActiveRecord::Base
  belongs_to :user

  validates :name, presence: true
  validates :access_token, presence: true
  validates :user, presence: true
end
