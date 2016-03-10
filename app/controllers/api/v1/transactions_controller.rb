class Api::V1::TransactionsController < ApplicationController
  before_action :init
  before_action :restrict_access

  def back_out
    tid = params[:id].to_i
    unless @authed_user.transactions.map(&:id).include? tid
      return head :not_found
    end
    transaction = Transaction.find_by(id: params[:id])
    # 500 because @authed_user has the transaction
    return head :internal_server_error unless transaction

    if transaction.invested
      errors = { transaction: ['has already been invested'] }
      return render json: errors, status: :bad_request
    end

    transaction.backed_out = true

    # Save and check for validation errors
    unless transaction.save
      return render json: transaction.errors, status: :unprocessable_entity
    end
    render json: transaction, status: :ok
  end
end
