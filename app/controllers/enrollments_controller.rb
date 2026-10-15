class EnrollmentsController < ApplicationController
  def index
    @enrollments = Enrollment.includes(:provider, :client).order(started_at: :desc, id: :desc)
  end

  def show
    @enrollment = Enrollment.includes(:provider, :client).find(params[:id])
  end
end
