class AaVendorsController < ApplicationController
  include Map
  

  load_and_authorize_resource
  
  def index
    
    @aa_vendors = @aa_vendors.search(params[:search]).page(params[:page])

    unless params[:province].blank?
      @aa_vendors = @aa_vendors.high_search(params[:province],params[:city],params[:region])
    end 
    
  end
  
  def new
    @vendor = AaVendor.new
  end

  def create
    @vendor = AaVendor.new(aa_vendor_params)

    if @vendor.save
      redirect_to edit_aa_vendor_path(@vendor), notice: '供应商信息添加成功!'
    else
      render action: 'new', notice: '供应商信息添加失败!'
    end
  end

  def edit
    @vendor = AaVendor.find_by_id(params[:id])
  end

  def update
    @vendor = AaVendor.find_by_id(params[:id])
   
    if @vendor.update_attributes(aa_vendor_params)
      redirect_to edit_aa_vendor_path(@vendor), notice: '供应商信息编辑成功!'
    else
      render action: 'edit', notice: '供应商信息编辑失败!'
    end
  end

  def show
    
  end

  def myself
    @aa_vendors = @aa_vendors.search_by_account(current_user.id)
    @vendor = AaVendor.find_by_id(@aa_vendors)
    render layout: 'form'
    
  end

  def update_by_myself
    @vendor = AaVendor.find_by_id(params[:vendor_id])

    if @vendor.update_attributes(aa_vendor_params)
      redirect_to myself_aa_vendors_path(@vendor), notice: '供应商信息编辑成功!'
    else
      render action: 'myself', notice: '供应商信息编辑失败!', layout: 'form'
    end
  end




  private
  def aa_vendor_params
    params.require(:aa_vendor).permit(:name,:address,:province,:city,:region,
      :contact,:contact_position,:mobile,:telephone,:fax,:email,:rescue_price,
      :trail_price,:car_route,:help_car,:trail_car,:flat_car,:crane_car,:memo,
      :dispatcher_status,:difficult_situation,:disabled,:rescue_base_fare,:account_no,:account_name,:open_bank,
      :rescue_include_kilometers,:rescue_unit_price,:trail_base_fare,:trail_include_kilometers,:trail_unit_price,
      :aa_contacts_attributes => [:name,:phone,:title,:_destroy,:id],
      :aa_trailers_attributes => [:license_no,:car_type,:gps_device_no,:gps_device_type,:status,:run_no,:insurance_no,:_destroy,:id],
      :aa_vendor_attachments_attributes => [:type,:name,:memo,:attachment,:_destroy,:id],    
      :aa_regions_attributes =>[{:service_item_ids=>[]}, :car_level, :support_level, :difficult_situation_level, :telephone, :province,:city,:district,:details,:minutes_of_arrival,:memo,:_destroy,:id],
      :aa_workers_attributes => [:no,:name,:mobile,:id_no,:driving_license_no,:qualification_no,:_destroy,:id]
      )
  end
end
