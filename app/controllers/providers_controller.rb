class ProvidersController < ApplicationController
  def index
    @providers = Provider.order(:name, :id)
  end

  def show
    @provider = Provider.find(params[:id])
    @enrollments = @provider.enrollments.includes(:client).order(started_at: :desc, id: :desc)
  end
end
