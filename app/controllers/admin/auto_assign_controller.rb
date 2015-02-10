class Admin::AutoAssignController < ApplicationController
  def stats
    @aa_cases = AutoAssignManager.tasks
    @users = AutoAssignManager.users
  end

  def start
    AutoAssignManager.start
    redirect_to admin_auto_assign_stats_path
  end

  def stop
    AutoAssignManager.stop
    redirect_to admin_auto_assign_stats_path
  end

  def logs
  end

  def logs_by_user
    @items = []
    @user = User.find_by_id(params[:user_id])
    unless @user.nil?
      @items = AutoAssignManager.history_of(@user)
    end
  end
end