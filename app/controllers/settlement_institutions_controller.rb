# encoding: utf-8
class SettlementInstitutionsController < ApplicationController
  load_and_authorize_resource
  def index
    @settlement_institutions = @settlement_institutions.page(params[:page])
  end

  def new
  end

  def edit
  end

  def create
    @settlement_institution = SettlementInstitution.new(settlement_institution_params)
    if @settlement_institution.save
      redirect_to settlement_institutions_path, notice: '创建成功.'
    else
      render action: 'new'
    end
  end

  def update
    if @settlement_institution.update(settlement_institution_params)
      redirect_to settlement_institutions_path, notice: '更新成功.'
    else
      render action: 'edit'
    end
  end

  private
  def settlement_institution_params
    params.require(:settlement_institution).permit(:name, :client_service_id, :code)
  end
end