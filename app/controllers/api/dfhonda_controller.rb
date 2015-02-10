# encoding: utf-8
class Api::DfhondaController < ApplicationController
  protect_from_forgery except: :receive_customer

  def receive_customer
    p params
    out = JSON.parse(params[:Customer])

    customer = Customer.new
    customer.client = Client.find_by_no(params[:CID])

    customer.driver_license_no = out["LicenseNO"]
    customer.name = out["CustomerName"]
    customer.out_source_no = out["CustomerId"]

    car = Car.new
    car.vin = out["VIN"]
    customer.cars << car

    service_define = ServiceItem.find_by_no(199)

    service = CustomerService.new
    service.car = car
    service.service_item = service_define
    service.begin = out["ServicesEffectDate"]
    service.end = out["ServicesExpiryDate"]
    customer.customer_services << service
    customer.save(validate: false)

    api_return = {}
    if customer.errors.count > 0
      api_return[:Code] = "999"
      api_return[:Description] = customer.errors
    else
      api_return[:Code] = "000"
      api_return[:Description] = customer.no
    end
    render json: api_return
  end
end