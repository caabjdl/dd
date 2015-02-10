# encoding: utf-8
class ServiceItemsController < ApplicationController
  load_and_authorize_resource

  def index
    @service_items = @service_items.search(params[:search]).order("id desc").page(params[:page])
  end

  def new
  end

  def create
    @service_item = ServiceItem.new(service_item_params)

    if @service_item.save
      redirect_to service_items_path, notice: '添加成功!'
    else
      render action: 'new', notice: '添加失败!'
    end

  end

  def edit
  end

  def update
    @service_item = ServiceItem.find_by_id(params[:id])
    if @service_item.update_attributes(service_item_params)
      redirect_to service_items_path, notice: '编辑成功!'
    else
      render action: 'edit', notice: '编辑失败!'
    end
  end

  def destroy
    @service_item = ServiceItem.find(params[:id])
    
    redirect_to service_items_path, :notice => "删除成功！"
   
  end


  private
  def service_item_params
    params.require(:service_item).permit(:category, :name, :no,:can_send_sms)
  end

end
