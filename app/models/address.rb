class Address < ApplicationRecord
  belongs_to :user

  validates :line1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip, presence: true
  validates :user, presence: true

  def as_json(options = {})
    json = super({
      except: [:user_id]
    }.merge(options))
    json
  end
end
