class Agex < ActiveRecord::Base
  belongs_to :user
  belongs_to :vice

  # Validations
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :user, presence: true
  validates :vice, presence: true
  validates :month, presence: true

  def as_json(options = {})
    json = super({
      except: [:vice_id]
    }.merge(options))
    json['vice'] = vice.name
    json
  end
end
