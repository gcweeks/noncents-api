class UserVice < ApplicationRecord
  belongs_to :user
  belongs_to :vice
end
