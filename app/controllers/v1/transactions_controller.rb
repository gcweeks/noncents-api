class V1::TransactionsController < ApplicationController
  before_action :init
  before_action :restrict_access

  def back_out
    tid = params[:id]
    raise NotFound unless @authed_user.transactions.map(&:id).include? tid
    transaction = Transaction.find_by(id: params[:id])

    if transaction.archived
      errors = { transaction: ['has already been archived'] }
      raise BadRequest.new(errors)
    end

    if transaction.invested
      errors = { transaction: ['has already been invested'] }
      raise BadRequest.new(errors)
    end

    transaction.backed_out = true

    # Save and check for validation errors
    raise UnprocessableEntity.new(transaction.errors) unless transaction.save
    render json: transaction, status: :ok
  end

  def restore
    tid = params[:id]
    raise NotFound unless @authed_user.transactions.map(&:id).include? tid
    transaction = Transaction.find_by(id: params[:id])

    if transaction.archived
      errors = { transaction: ['has already been archived'] }
      raise BadRequest.new(errors)
    end

    if transaction.invested
      errors = { transaction: ['has already been invested'] }
      raise BadRequest.new(errors)
    end

    transaction.backed_out = false

    # Save and check for validation errors
    raise UnprocessableEntity.new(transaction.errors) unless transaction.save
    render json: transaction, status: :ok
  end
end
