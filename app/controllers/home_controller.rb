class HomeController < ApplicationController
  before_filter :authenticate_user!
  def index
  end

  def history
	@aa_rescues = AaRescue.joins(:aa_case).search(params[:customer_mobile],params[:customer_name],params[:car_license_no]).where('aa_cases.id != ?',params[:id])
  	
  	render layout: 'empty'
  end
end