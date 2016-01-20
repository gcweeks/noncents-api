class Api::V1::BanksController < ApplicationController
  before_action :init
  before_action :restrict_access
  before_action :set_bank, only: [:show, :update, :destroy]

  # GET /banks
  def index
    @banks = Bank.all
    return render json: @banks, status: :ok
  end

  # GET /banks/1
  def show
    return render json: @bank, status: :ok
  end

  # POST /banks
  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      return render json: @bank, status: :created
    else
      return render json: @bank.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /banks/1
  def update
    if @bank.update(bank_params)
      return render json: @bank, status: :ok
    else
      return render json: @bank.errors, status: :unprocessable_entity
    end
  end

  # DELETE /banks/1
  def destroy
    @bank.destroy
    return head :no_content
  end

  private
    def set_bank
      @bank = Bank.find(params[:id])
    end

    def bank_params
      params.require(:bank).permit(:name)
    end
end
