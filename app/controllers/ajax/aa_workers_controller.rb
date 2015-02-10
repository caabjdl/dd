class Ajax::AaWorkersController < ApplicationController
  def show
    @aa_worker = AaWorker.find_by_id(params[:id])
  end
end