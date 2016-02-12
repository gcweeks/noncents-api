class UserVice < ActiveRecord::Base
  belongs_to :user
  belongs_to :vices
end
