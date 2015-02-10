#encoding: utf-8
class AaCasesController < ApplicationController
  include Map
  include AaCasesQuery
  
  load_and_authorize_resource :except => [ :batch_accounting]
  
  def index
    @all_aa_cases = get_aa_cases(@aa_cases)
    @aa_cases = @all_aa_cases.page(params[:page])

    respond_to do |format|
      format.html
      format.csv { send_data @all_aa_cases.csv_file }
      format.xls
    end
  end

  def review
    @aa_cases = get_aa_cases(@aa_cases).pingan_cases.page(params[:page])
  end

  def wait_pingan
    @aa_cases = AaCase.where("status = '待平安系统确认'").order('id desc').page(params[:page])
  end

  def untreated
    @aa_cases = @aa_cases.untreated.page(params[:page])
    render :layout => 'list' 
  end

  def handle
    @aa_cases = get_aa_cases(@aa_cases).handle.page(params[:page])
    render :layout => 'list' 
  end

  def accounting
    @aa_cases = get_aa_cases(@aa_cases).accounting.page(params[:page]).per(100)
    render :layout => 'list' 
  end

  def accounting_sure
    @aa_cases = get_aa_cases(@aa_cases).accounting_sure.page(params[:page]).per(100)
    render :layout => 'list'
  end

  def accounting_no_vendor
    @aa_cases = get_aa_cases(@aa_cases).accounting_no_vendor.page(params[:page]).per(100)
    render :layout => 'list' 
  end

  #导出功能 目前禁用
  def export
    VisitHistory.create(:user_id=>current_user.id, :item_type => "AaCase", :visited_at=>Time.now, :action => 'export',:url=>URI.unescape(request.url))
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    export_xls = Export::ExportXls.new(get_aa_cases(@aa_cases).limit(5000),"#{Rails.root}/app/views/aa_cases/export.xls.erb")
    send_data export_xls.gzip(timestamp + "_cases.xls"),:type => 'application/zip',:filename => timestamp + '_cases.zip'
  end

  def mine
    @aa_cases = get_aa_cases(@aa_cases).filter_by_owner_and_status(current_user).page(params[:page])
    render :layout => 'list' 
  end

  def mine_all
    @aa_cases = get_aa_cases(@aa_cases).mine(current_user).page(params[:page])
    render :layout => 'list'
  end

  def unhandle
    @aa_cases = @aa_cases.unhandle.page(params[:page])
    render :layout => 'list' 
  end

  def batch_accounting
    AaCase.batch_accounting(params[:accountings])
    redirect_to request.referer, notice: '批量操作成功'
  end

  def create
    @aa_case = AaCase.new(aa_case_params)
    
    if @aa_case.save
      WebsocketRails[:aa_cases].trigger(:created, @aa_case)
      redirect_to aa_cases_path, notice: '创建成功.'
    else
      render action: 'new'
    end
  end

  def analysis
    @aa_rescues = PaperTrail::Version.where("item_type = 'AaRescue'
        and object_changes like '%aa_vendor_id%'").limit(20)
  end

  def new
    @aa_case.init_data
    unless params[:customer_service_id].nil?
      customer_service = CustomerService.find_by_id(params[:customer_service_id])
      if customer_service.customer
        @aa_case.customer_name = customer_service.customer.name
        @aa_case.car_license_no = customer_service.customer.driver_license_no
        @aa_case.customer_mobile = customer_service.customer.mobile
        @aa_case.customer_id = customer_service.customer.id
        @aa_case.client_service_name = customer_service.customer.client_service_name
        @aa_case.customer_service_id = customer_service.id
        @aa_case.car_license_no = customer_service.car.license_no if customer_service.car
        @aa_case.car_vin = customer_service.car.vin if customer_service.car
        @aa_case.car_model = customer_service.car.model if customer_service.car
      end
    end
    unless params[:init].nil?
      init = JSON.parse(params[:init])
      @aa_case.out_source_no = init["out_source_no"]
      @aa_case.data_source = init["data_source"]
    end
  end

  def take_owner
    aa_rescue = @aa_case.prepare_rescue(current_user)
    redirect_to edit_aa_rescue_path(aa_rescue)
  end

  def assign
    user = User.find_by_id(params[:user_id])
    aa_rescue = @aa_case.prepare_rescue(user)
    @aa_case.assign_owner(user)
    @aa_case.assign_dispatcher(user)
    @aa_case.save

    WebsocketRails.users[user.id].send_message(:assigned, { no: @aa_case.no }, :namespace => :aa_cases) unless UserOnlineManager.connections_count_of(user) == 0

    redirect_to request.referer
  end

  def pingan_api_log
  end

  def query_pingan_salvation
  end

  def edit
  end

  def update
    @aa_case = AaCase.base_scope.find_by_id(params[:id])

    if @aa_case.update_attributes(aa_case_params)
      redirect_to aa_cases_path, notice: '更新成功.'
    else
      render action: 'edit' 
    end
  end


  def list_by_aa_vendor
    @all_aa_cases = get_aa_cases(@aa_cases)
    @aa_cases = @all_aa_cases.page(params[:page])
    render :layout => 'list'
  end

  private
  def aa_case_params
    params.require(:aa_case).permit(:no, :owner_no,:connected_at, :appointment_at, :from_coordinate_address,:customer_id,:customer_service_id, :customer_account, :customer_no, :customer_name, :customer_mobile, :car_vin,
      :car_license_no, :car_model, :client_service_name, :rescue_reason,:rescue_type, :memo, :from_province, :data_source, :out_source_no,
      :from_city, :from_region, :from_details, :to_province, :to_city, :to_region, :to_details, :car_color)
  end

end
