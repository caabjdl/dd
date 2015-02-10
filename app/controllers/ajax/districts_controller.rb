class Ajax::DistrictsController < ApplicationController
  def provinces
    @list = District.provinces(params[:name])
  end

  def cities
    @list = District.cities(params[:province], params[:name])
  end

  def regions
    @list = District.regions(params[:province], params[:city], params[:name])
  end
end
