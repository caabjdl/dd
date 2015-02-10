# encoding: utf-8
class Api::Common::CustomersController < ApplicationController
  protect_from_forgery except: [:receive, :update, :delete]
  
  def receive
    render json: CommonCustomerApiService.instance.receive_customer(JSON.parse(request.body.read)).to_json
  end

  def update
    
  end

  def delete
    render json: CommonCustomerApiService.instance.delete_customer(JSON.parse(request.body.read)).to_json
  end

end