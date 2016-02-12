class Api::V1::UsersController < ApplicationController
  before_action :init
  before_action :restrict_access
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /users/me
  def get_me
    render json: @authed_user, status: :ok
  end

  # PATCH/PUT /users/me
  def update_me
    if @authed_user.update!(user_params)
      return render json: @authed_user, status: :ok
    end
    render json: @authed_user.errors, status: :unprocessable_entity
  end
end
