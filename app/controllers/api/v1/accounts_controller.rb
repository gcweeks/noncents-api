class Api::V1::AccountsController < ApplicationController
  before_action :init
  before_action :restrict_access
  before_action :set_account, only: [:show, :update, :destroy]

  # GET /accounts/1
  def show
    return render json: @account, status: :ok
  end

  # POST /accounts
  def create
    # Find user via "account[user_id]" or return 404
    @user = User.find(account_params[:user_id])
    # Alternately, we could have done this:
    # begin
    #   @user = User.find(account_params[:user_id])
    # rescue ActiveRecord::RecordNotFound => e
    #   @user = nil
    #   logger.info e
    # end
    @account = @user.accounts.new(account_params)

    if @account.save
      return render json: @account, status: :created
    else
      return render json: @account.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /accounts/1
  def update
    if @account.update(account_params)
      return render json: @account, status: :ok
    else
      return render json: @account.errors, status: :unprocessable_entity
    end
  end

  # DELETE /accounts/1
  def destroy
    @account.destroy
    return head :no_content
  end

  private
    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:user_id, :acctNum, :routNum, :cardNum, :cardName,
        :expMonth, :expYear, :zipcode)
    end
end
