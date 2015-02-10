class Admin::ClientApiProfilesController < ApplicationController
  load_and_authorize_resource

  def index
    @client_api_profiles = @client_api_profiles.search(params[:search]).page(params[:page])
  end

  def new
  end

  def create
    @client_api_profile = ClientApiProfile.new(client_api_profile_params)
    if @client_api_profile.save
      redirect_to admin_client_api_profiles_path, notice: '接口配置创建成功.'
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @client_api_profile.update(client_api_profile_params)
      redirect_to admin_client_api_profiles_path, notice: '接口配置更新成功.'
    else
      render action: 'edit'
    end
  end

  private
  def client_api_profile_params
    params.require(:client_api_profile).permit(:client_service_name, :cid, :secret, :disabled, :callback, :client_id)
  end
end