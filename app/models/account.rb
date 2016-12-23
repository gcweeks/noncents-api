class Account < ApplicationRecord
  belongs_to :bank
  belongs_to :user
  has_many :transactions

  validates :plaid_id, presence: true
  validates :name, presence: true
  validates :account_type, presence: true
  validates :institution, presence: true
  validates :bank, presence: true
  validates :user, presence: true

  def as_json(options = {})
    json = super({
      except: [:plaid_id, :account_num, :routing_num, :dwolla_id,
               :user_id]
    }.merge(options))
    json['plaid_auth'] = self.bank.plaid_auth
    json['plaid_connect'] = self.bank.plaid_connect
    json['plaid_needs_reauth'] = self.bank.plaid_needs_reauth
    json
  end
end
