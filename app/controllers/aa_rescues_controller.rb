#encoding: utf-8
class AaRescuesController < ApplicationController
  protect_from_forgery
  authorize_resource

  def edit
    @aa_rescue = AaRescue.find_by_id(params[:id])
    if @aa_rescue.aa_vendor_id.nil? && current_user.user_handle_aa_vendors.count == 1
      @aa_rescue.aa_vendor = current_user.user_handle_aa_vendors.first
    end
    #@aa_rescue.assign_worker(User.find_by_no("6511"))
    #SmsApiWorker.perform_async("customer_received",@aa_rescue.aa_case.id)
    VisitHistory.create(:user_id=>current_user.id, :item_id => @aa_rescue.id, :item_type => @aa_rescue.class.name, :visited_at=>Time.now, :action => 'edit')
    if @aa_rescue.nil?
      redirect_to aa_cases_path, error: "找不到对应的接线记录."
    end
  end

  def show
    @aa_rescue = AaRescue.find_by_id(params[:id])
    if @aa_rescue.nil?
      redirect_to aa_cases_path, error: "找不到对应的接线记录."
    end
  end

  def update
    @aa_rescue = AaRescue.find_by_id(params[:id])

    if @aa_rescue.update_attributes(aa_rescue_params)
      redirect_to edit_aa_rescue_path(@aa_rescue)
    else
      render action: 'edit' 
    end
  end

  def view_by_aa_vendor
    @aa_rescue = AaRescue.find_by_id(params[:id])

    if @aa_rescue.nil?
      redirect_to list_by_aa_vendor_aa_cases_path, error: "找不到对应的接线记录."
    end
    render :layout => 'list'
  end

  def tracking
    aa_rescue = AaRescue.find_by_id(params[:id])
    @tracking_back = "0"
    @tracking_back = aa_rescue.tracking unless aa_rescue.aa_worker.aa_trailer.device.nil? unless aa_rescue.aa_worker.aa_trailer.nil? unless aa_rescue.aa_worker.nil? unless aa_rescue.nil?

    render layout: 'map'
  end

  def worker_tracking
    worker_job = WorkerJob.find_by_id(params[:id])
    @tracking_data = worker_job.tracking_data
    render layout: 'map_abc'
  end

  def send_photo
    @aa_rescue = AaRescue.find_by_id(params[:id])
    PinganApiWorker.new.send_photo(@aa_rescue.aa_case_id)
    redirect_to edit_aa_rescue_path(@aa_rescue)
  end

  def send_sms
    @aa_rescue = AaRescue.find_by_id(params[:id])
    phone = params[:sms_phone].blank? ? @aa_rescue.aa_case.customer_mobile : params[:sms_phone]
  end

  private
  def aa_rescue_params
    params.require(:aa_rescue).permit(:memo,:aa_worker_id, :aa_vendor_id, :id, :aa_vendor_name, :map_range_arrive,:map_range_empty_run,:map_range_drag,
      :contacted_at, :plan_arrive_at, :arrived_at, :completed_at, :dispatched_at, :canceled_at,:map_range_back, 
      :distance_arrive, :distance_drag, :distance_back, :distance_empty_run, :aa_trailer_license_no,:satisfaction,
      :aa_worker_name, :aa_worker_phone, :photo_phone, :fee, :cancel_reason, :addition_fee, :other_fee,:aa_trailer_id,
      :aa_case_attributes => [:customer_account,:from_coordinate_address, :customer_no,:appointment_at, :customer_name, :customer_mobile, :rescue_type, :car_vin,
      :car_license_no, :car_model,:car_color, :client_service_name, :rescue_reason, :memo, :from_province,
      :from_city, :from_region, :from_details, :to_province, :to_city, :to_region, :to_details, :id],
      :aa_case_logs_attributes => [:log_type, :content, :labor, :log_at, :status, :eta, :id])
  end
end
