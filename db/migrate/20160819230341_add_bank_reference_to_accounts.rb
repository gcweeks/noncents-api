class AddBankReferenceToAccounts < ActiveRecord::Migration
  def change
    add_reference :accounts, :bank, type: :uuid, index: true
  end
end
