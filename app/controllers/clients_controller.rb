class ClientsController < ApplicationController
  def index
    @clients = Client.order(:name, :id)
  end

  def show
    @client = Client.find(params[:id])
    @enrollments = @client.enrollments.includes(:provider).order(started_at: :desc, id: :desc)
    @journal_entries = @client.journal_entries.recent_first
  end
end
