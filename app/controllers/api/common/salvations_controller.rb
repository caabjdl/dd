# encoding: utf-8
class Api::Common::SalvationsController < ApplicationController
  protect_from_forgery except: [:receive, :delete]
  
  def receive
    #data = JSON.parse(request.body.read)
    render json: CommonSalvationApiService.instance.receive_salvation(JSON.parse(request.body.read)).to_json
  end

  def delete
    render json: CommonSalvationApiService.instance.delete_salvation(JSON.parse(request.body.read)).to_json
  end

end