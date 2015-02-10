class Ajax::UsersController < ApplicationController

  before_filter :authenticate_user!
  
  def assign_by_aa_case
    @users = []
    aa_case = AaCase.base_scope.find_by_id(params[:aa_case_id])
    unless aa_case.nil?
      @users = UserOnlineManager.online_users.joins(:user_handle_client_services).where("users.role in ('调度','平安调度','调度组长','救援工','全局调度') and client_services.name = ?", aa_case.client_service_name).pluck(:id, :no, :name)
      #@users = User.unlocked.where("role in ('调度','平安调度','调度组长','救援工','全局调度')").pluck(:id, :no, :name)
      #current_user.underlings.joins(:client_services).where("client_services.name" => aa_case.client_service_name).pluck(:id, :no, :name)
    end

    render "id_no_and_name"
  end

end