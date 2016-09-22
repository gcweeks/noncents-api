class AuthEvent < ApplicationRecord
  belongs_to :user

  validates :ip_address, presence: true
  # Booleans must be validated like this, otherwise 'false' and 'nil' evaluate
  # to the same thing and the validation fails.
  validates_inclusion_of :success, :in => [true, false]
  validates :user, presence: true
end
