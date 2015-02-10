class Ajax::ClientServicesController < ApplicationController
  def list_by_name
    @client_services = ClientService.enabled.search(params[:name]).pluck(:name)
  end

  def get_settlements
    @settlement_institutions = SettlementInstitution.where(client_service_id: params[:id])
    @other_settlement_institutions = User.find(params[:user_id]).settlement_institutions.where("client_service_id != ?",params[:id]).pluck(:id)
  end
end