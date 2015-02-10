# encoding: utf-8
class ClientServicesController < ApplicationController
  load_and_authorize_resource

  def index
    @client_services = @client_services.search(params[:search]).page(params[:page])
  end

  def new
  end

  def edit
  end

  def create
    @client_service = ClientService.new(client_service_params)
    if @client_service.save
      redirect_to client_services_path, notice: '可调度来源创建成功.'
    else
      render action: 'new'
    end
  end

  def update
    if @client_service.update(client_service_params)
      redirect_to client_services_path, notice: '可调度来源更新成功.'
    else
      render action: 'edit'
    end
  end

  def set_auto_assign
    case params[:type]
    when "disable"
      ClientService.where("id in (:ids)", :ids => params[:ids].split(',')).update_all(:can_auto_assign => false)
    when "enable"
      ClientService.where("id in (:ids)", :ids => params[:ids].split(',')).update_all(:can_auto_assign => true)
    else
    end
    redirect_to request.referer
  end

  private
  def client_service_params
    params.require(:client_service).permit(:name, :disabled, :can_auto_assign,:can_send_sms,:required_customer_account)
  end
end
