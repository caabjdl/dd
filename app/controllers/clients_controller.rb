# encoding: utf-8
class ClientsController < ApplicationController
  load_and_authorize_resource
  def index
    @clients = @clients.order("id desc").page(params[:page])
  end

  def new
  end

  def edit
  end

  def create
    if @client.save
      redirect_to clients_url, notice: "客户信息创建成功."
    else
      render action: "new"
    end
  end

  def update
    @client = Client.find_by_id(params[:id])

    if @client.update_attributes(client_params)
      redirect_to clients_url, notice: "客户信息更新成功."
    else
      render action: "edit"
    end
  end

  private
  def client_params
    params.require(:client).permit(:no, :name, :fax, :contact, :telephone)
  end
end
