class Vice < ActiveRecord::Base
  has_many :user_vices
  has_many :users, through: :user_vices
end
