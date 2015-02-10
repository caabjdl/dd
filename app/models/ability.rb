# encoding: utf-8
require 'sourcify'
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    #TODO: account_type和role 可能需要做集合处理
    case user.account_type
    when "供应商"
      can [:myself, :update_by_myself], AaVendor
      can [:list_by_aa_vendor, :map], AaCase
      can [:view_by_aa_vendor], AaRescue
    when "直派供应商"
      can [:use], AaCase
      can [:mine, :mine_all], AaCase
      can [:take_owner, :create, :edit, :update, :map], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)
      can [:edit, :update,:send_sms], AaRescue
    else
      case user.role
      when "系统管理员", "管理员"
        can :manage, :all
      when "接线"
        can [:use], AaCase
        can [:new], AaCase
        can [:index, :create, :edit, :update, :query_pingan_salvation], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)
      when "接线组长"
        can [:use], AaCase
        can [:new], AaCase
        can [:export], AaCase
        can [:index, :create, :edit, :update, :query_pingan_salvation], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)
      when "供应商管理"
        can [:index, :new, :create, :edit, :update, :show, :map], AaVendor
        can [:manage], AccountingJob
      when "供应商全局管理"
        can [:index, :new, :create, :edit, :update, :show, :map], AaVendor
        can [:manage], AccountingJob
      when "调度"
        can [:use], AaCase
        can [:new], AaCase
        can :manage, Customer
        can [:mine, :mine_all], AaCase
        can [:index, :unhandle, :take_owner, :create, :update, :map], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)
        can [:edit, :update, :send_sms,:worker_tracking], AaRescue
      when "平安调度"
        can [:use], AaCase
        can [:new], AaCase
        can [:mine, :mine_all], AaCase
        can [:handle, :take_owner, :create, :edit, :update, :query_pingan_salvation, :map], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)        
        can [:edit, :update,:send_sms,:worker_tracking], AaRescue
      when "调度组长"
        can [:use], AaCase
        can [:new], AaCase
        can :manage, Customer
        can [:mine, :mine_all], AaCase
        can [:index, :handle, :unhandle, :untreated, :take_owner, :create, :edit, :update, :query_pingan_salvation, :map, :assign, :export], AaCase, :client_service_name => user.user_handle_client_services.pluck(:name)
        can [:edit, :update,:send_sms,:worker_tracking], AaRescue
      when "全局调度"
        can [:use], AaCase
        can :manage, Customer
        can [:mine, :mine_all], AaCase
        can [:index, :handle, :unhandle, :untreated, :take_owner, :create, :new, :edit, :update, :query_pingan_salvation, :map, :assign, :export], AaCase
        can [:edit, :update,:send_sms,:worker_tracking], AaRescue
        can [:manage], ClientService
        can [:manage], District
      when "结算对账"
        can [:use], AaCase
        can [:index, :edit, :update, :map, :export, :accounting, :accounting_sure, :accounting_no_vendor], AaCase
        can [:edit, :update,:worker_tracking], AaRescue
        can [:manage], ExportFile
        can [:manage], :finance_excel_revise
        can [:manage], AccountingJob
      when "质检"
        can [:use], AaCase
        can [:index, :edit, :update, :map, :export], AaCase
        can [:edit, :update,:worker_tracking], AaRescue
        can [:manage], ExportFile
        can [:manage], AccountingJob
      when "救援工"
        can :manage, WorkerJob
      when "大客户查阅"
        can [:use], AaCase
        can [:review, :pingan_api_log], AaCase, :settlement_institution_id => user.settlement_institutions.pluck(:id)
        can [:show,:worker_tracking], AaRescue
      end
    end

  end
end