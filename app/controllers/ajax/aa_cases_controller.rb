class Ajax::AaCasesController < ApplicationController

  def history_count_by_name
    @count = 0
    @count = AaCase.base_scope.where(:customer_name => params[:name]).where("id <> ?", params[:from_aa_case_id]).length unless params[:name].blank?
    render action: :history
  end

  def history_count_by_phone
    @count = 0
    @count = AaCase.base_scope.where(:customer_mobile => params[:phone]).where("id <> ?", params[:from_aa_case_id]).length unless params[:phone].blank?
    render action: :history
  end

  def history_count_by_license_no
    @count = 0
    @count = AaCase.base_scope.where(:car_license_no => params[:license_no]).where("id <> ?", params[:from_aa_case_id]).length unless params[:license_no].blank?
    render action: :history
  end

  def history_count_by_car_vin
    @count = 0
    @count = AaCase.base_scope.where(:car_vin => params[:car_vin]).where("id <> ?", params[:from_aa_case_id]).length unless params[:car_vin].blank?
    render action: :history
  end
end