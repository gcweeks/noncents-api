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
               :user_id, :balance_refreshed_at]
    }.merge(options))
    json['plaid_auth'] = self.bank.plaid_auth
    json['plaid_connect'] = self.bank.plaid_connect
    json['plaid_needs_reauth'] = self.bank.plaid_needs_reauth
    json
  end

  def populate(plaid_account, balance_only = false)
    self.current_balance = plaid_account.current_balance
    self.available_balance = if plaid_account.available_balance.present?
                               plaid_account.available_balance
                             else
                               plaid_account.current_balance
                             end
    self.balance_refreshed_at = DateTime.current
    return self if balance_only
    self.name = plaid_account.meta['name']

    self.account_type = plaid_account.type.to_s
    self.account_subtype = plaid_account.subtype
    self.institution = plaid_account.institution.to_s
    if plaid_account.numbers.present? # Auth
      self.routing_num = plaid_account.numbers[:routing]
      self.account_num = plaid_account.numbers[:account]
      if self.account_num && self.account_num.length > 4
        self.account_num_short = self.account_num[-4..-1]
      end
    elsif plaid_account.meta['number'].present? # Connect
      self.account_num_short = plaid_account.meta['number']
    end

    self
  end
end
