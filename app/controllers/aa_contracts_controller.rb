class AaContractsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @contract = AaContract.where(aa_vendor_id: params[:aa_vendor_id] )
    @aa_contracts = @contract.search(params[:search]).page(params[:page])

  end

  def new
    @aa_contract.aa_vendor_id = params[:aa_vendor_id]
  end

  def create
    @aa_contract = AaContract.new(aa_contract_params) 
    
    if @aa_contract.save
      redirect_to aa_contracts_path(:aa_vendor_id => @aa_contract.aa_vendor_id)
    else
      render action: 'new'
    end

  end

  def edit

  end

  def update
    @aa_contract = AaContract.find_by_id(params[:id])

    if @aa_contract.update_attributes(aa_contract_params)
      redirect_to aa_contracts_path(:aa_vendor_id => @aa_contract.aa_vendor_id)
    else
      render action: 'new'
    end

  end

  def destroy
    @aa_contract = AaContract.find(params[:id])

    @aa_contract.destroy

    redirect_to aa_contracts_path(:aa_vendor_id => @aa_contract.aa_vendor_id), :notice => "删除成功!"

  end

 

  private
  def aa_contract_params
    params.require(:aa_contract).permit(:aa_vendor_id,:no,:from,:to,:contract_type,:status,
      :aa_contract_attachments_attributes => [:type,:memo,:name,:attachment,:_destroy,:id]
      )
  end

end
