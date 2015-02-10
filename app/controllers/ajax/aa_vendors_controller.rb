class Ajax::AaVendorsController < ApplicationController
  
  def list_by_name
    @aa_vendors = []
    if current_user.user_handle_aa_vendors.length == 0
      @aa_vendors = AaVendor.available.search(params[:name]).pluck(:id, :no, :name, :aa_vendor_type) unless params[:name].blank?
    else
      @aa_vendors = current_user.user_handle_aa_vendors.available.search(params[:name]).pluck(:id, :no, :name, :aa_vendor_type) unless params[:name].blank?
    end
  end

  def show
    @aa_vendor = AaVendor.find_by_id(params[:id])
  end

  def workers  
    vendor = AaVendor.find_by_id(params[:id])
    @phone = vendor.get_help_telephone(params[:province],params[:city],params[:district])
    @aa_workers = vendor.aa_workers.joins(:user).where("users.online_status = '空闲' and users.online_status is not null")
    @aa_trailers = vendor.aa_trailers
  end

  def cul_fee
    aa_rescue = AccountingJob.find_by_id(params[:id]).aa_rescue
    aa_rescue.distance_arrive = params[:arrive]
    aa_rescue.distance_drag = params[:drag]
    aa_rescue.distance_back = params[:back]
    aa_rescue.distance_empty_run = params[:empty_run]
    @fee = aa_rescue.accounting_price
  end

  def level
    vendor = AaVendor.find_by_id(params[:id])
    aa_region = vendor.aa_regions.where(province: params[:province],city:params[:city],district: params[:district]).first
    @level = aa_region.nil?  ? '' : aa_region.car_level
  end
end