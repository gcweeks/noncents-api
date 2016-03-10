class Fund < ActiveRecord::Base
  belongs_to :user

  def deposit!(amount)
    self.balance += amount
    save!
  end
end
