class DistrictsController < ApplicationController
  load_and_authorize_resource
  def index
    @districts = @districts.search(params[:search]).page(params[:page])
  end

  def new
  end

  def create
    @district = District.new(district_params)

    if @district.save
      redirect_to districts_path
    else
      render action: 'new'
    end

  end

  def destroy
    @district = District.find(params[:id])

    unless @district.region.blank? || @district.city.blank?
      then
      @district.destroy
      redirect_to districts_path, :notice => '删除成功!'
      else
      redirect_to districts_path, :notice => '删除失败,只允许删除某个区!' 
    end
  end

  def set_auto_assign
    case params[:type]
    when "disable"
      District.where("id in (:ids)", :ids => params[:ids].split(',')).update_all(:can_auto_assign => false)
    when "enable"
      District.where("id in (:ids)", :ids => params[:ids].split(',')).update_all(:can_auto_assign => true)
    else
    end
    redirect_to request.referer
  end

  private
  def district_params
    params.require(:district).permit(:code,:province,:city,:region)
  end


end