class Api::V1::UsersController < ApplicationController
  before_action :init
  before_action :restrict_access
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /users
  def index
    @users = User.all
    return render json: @users, status: :ok
  end

  # GET /users/1
  def show
    return render json: @user, status: :ok
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      return render json: @user, status: :created
    else
      return render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      return render json: @user, status: :ok
    else
      return render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    return head :no_content
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:number, :fname, :lname, :address, :city,
        :state, :zip, :dob, :token)
    end
end
