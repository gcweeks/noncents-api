class Api::V1::BanksController < ApplicationController
  before_action :init
  before_action :restrict_access
  before_action :set_bank, only: [:show, :update, :destroy]

  # GET /banks/1
  def show
    render json: @bank, status: :ok
  end

  # POST /banks
  def create
    @bank = Bank.new(bank_params)

    return render json: @bank, status: :created if @bank.save
    render json: @bank.errors, status: :unprocessable_entity
  end

  # PATCH/PUT /banks/1
  def update
    return render json: @bank, status: :ok if @bank.update(bank_params)
    render json: @bank.errors, status: :unprocessable_entity
  end

  # DELETE /banks/1
  def destroy
    @bank.destroy
    head :no_content
  end

  private

  def set_bank
    @bank = Bank.find(params[:id])
  end

  def bank_params
    params.require(:bank).permit(:name)
  end
end
