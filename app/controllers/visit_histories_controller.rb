class VisitHistoriesController < ApplicationController
  load_and_authorize_resource
  def index
    @visit_histories = @visit_histories.search(params[:search]).page(params[:page])
  end
end