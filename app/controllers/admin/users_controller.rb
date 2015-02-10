class Admin::UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @users = @users.filter_roles.search(params[:search]).page(params[:page])
  end

  def new
  end

  def online
    @users = UserOnlineManager.online_users.page(params[:page])
  end

  def offline
    user = User.find_by_id(params[:id])
    unless user.nil?
      WebsocketRails.users[user.id].send_message(:offline, { id: user.id }, :namespace => :users) unless UserOnlineManager.connections_count_of(user) == 0
    end
    redirect_to online_admin_users_path
  end

  def create
    @user = User.new(create_user_params)
    
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    if @user.save
      redirect_to admin_users_url, :notice => "账户创建成功"
    else
       render action: 'new'
    end
  end
  
  def edit
  end

  def update
    u_params = update_user_params

    @user = User.find_by_id(params[:id])

    if u_params[:password].blank?
      u_params.delete("password")
      u_params.delete("password_confirmation")
    end

    if @user.update_attributes(u_params)
      if params[:locked] == "1"
        @user.lock_access!
      else
        @user.unlock_access!
      end

      redirect_to edit_admin_user_path(@user), :notice => "账户更新成功"
    else
      render action: 'edit'
    end
  end

  def destroy
    user = User.find_by_id(params[:id])
    user.lock_access!
    redirect_to admin_users_url
  end

  private

  def create_user_params
    params.require(:user).permit(:email, :password, :role, :no, :department, :name, :password_confirmation, :manager_id, :auto_assign_interval,
      :can_auto_assign_to, :account_type,{:settlement_institution_ids=>[]}, { :user_handle_client_service_ids => [] }, { :user_handle_aa_vendor_ids => [] },
      :user_handle_districts_attributes => [:province, :city, :region, :_destroy, :id]
      )
  end

  def update_user_params
    params.require(:user).permit(:email, :role, :no, :department, :name, :manager_id, :password, :password_confirmation, :auto_assign_interval,
      :can_auto_assign_to, :account_type,{:settlement_institution_ids=>[]}, { :user_handle_client_service_ids => [] }, { :user_handle_aa_vendor_ids => [] },
      :user_handle_districts_attributes => [:province, :city, :region, :_destroy, :id]
      )
  end
end
