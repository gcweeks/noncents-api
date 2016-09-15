class V1::VicesController < ApplicationController
  before_action :init

  # GET /vices
  def index
    # Return the name of all vices
    render json: Vice.all.map(&:name), status: :ok
  end
end
