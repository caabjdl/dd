# encoding: utf-8
require 'singleton'

class CommonCustomerApiService
  include Singleton

  def receive_customer(data)
    data_back = Hash.new
    messages = validate_data(data)
    if messages.length == 0
      profile = ClientApiProfile.find_by_cid(data["cid"])
      unless profile.nil? || profile.disabled
        customer = Customer.find_by_out_source_no_and_client_service_name(data["no"], profile.client_service_name)
        # 没有这个客户就是创建,否则就是更新
        if customer.nil?
          customer = Customer.new
          customer.client_service_name = profile.client_service_name
          customer.client = profile.client
          data_back["return_code"] = "1"
          data_back["return_message"] = "客户创建成功."
        else
            data_back["return_code"] = "2"
            data_back["return_message"] = "客户更新成功."
        end
        set_customer(customer, data)
        if customer.save
          data_back["user_id"] = customer.no
        else
          data_back["return_code"] = "99"
          data_back["return_message"] = "数据不完整. #{customer.errors.inspect}"
          data_back["user_id"] = nil
        end
      end
    else
      data_back["return_code"] = "99"
      data_back["return_message"] = "#{messages.inspect}"
      data_back["user_id"] = nil
    end

    return data_back
  end

  def delete_customer(data)
    data_back = Hash.new
    messages = validate_delete_data(data)
    if messages.length == 0
      profile = ClientApiProfile.find_by_cid(data["cid"])
      unless profile.nil? || profile.disabled
        customer = Customer.find_by_out_source_no_and_client_service_name(data["no"], profile.client_service_name)
        # 没有这个客户就是创建,否则就是更新
        unless customer.nil?
          customer.disable
          data_back["return_code"] = "1"
          data_back["return_message"] = "客户删除成功."
        else
          data_back["return_code"] = "3"
          data_back["return_message"] = "客户无法找到."
        end
        if customer.save
          data_back["user_id"] = customer.no
        else
          data_back["return_code"] = "99"
          data_back["return_message"] = "数据不完整. #{customer.errors.inspect}"
          data_back["user_id"] = nil
        end
      end
    else
      data_back["return_code"] = "99"
      data_back["return_message"] = "#{messages.inspect}"
      data_back["user_id"] = nil
    end

    return data_back
  end

  def query_customer
    
  end

  private
  def set_customer(customer, data)
    customer.out_source_no = data["no"]
    customer.name = data["name"]
    customer.mobile = data["phone"]
    customer.pid = data["pid"]

    unless data["car_vin"].blank? && data["car_model"].blank? && data["car_license_no"].blank?
      car = customer.cars.where("client_service_name = :client_service_name and (vin = :vin or license_no = :license_no)", 
        :client_service_name => customer.client_service_name, :vin => data["car_vin"], :license_no => data["car_license_no"]).first
      if car.nil?
        car = Car.new
        car.client_service_name = customer.client_service_name
        customer.cars << car
      end
      car.vin = data["car_vin"]
      car.license_no = data["car_license_no"]
      car.model = data["car_model"]
    end

    unless data["services"].blank? && data["services"].length == 0
      data["services"].each do |item|
        service_item = ServiceItem.find_by_no(item["no"])
        unless service_item.nil?
          service = CustomerService.new
          service.service_item = service_item
          service.description = item["description"]
          service.begin = item["begin"]
          service.end = item["end"]
          customer.customer_services << service
        end
      end
    end

  end

  def validate_data(data)
    messages = []

    messages << "CID不能为空." if data["cid"].blank?

    unless data["cid"].blank?
      profile = ClientApiProfile.find_by_cid(data["cid"])
      messages << "CID不合法或者已被禁用." if profile.nil? || profile.disabled
    end

    messages << "客户编号不能为空." if data["no"].blank?
    messages << "客户姓名不能为空." if data["name"].blank?
    messages << "联系电话不能为空." if data["phone"].blank?

    unless data["services"].blank? || data["services"].length == 0
      data["services"].each do |item|
        messages << "服务编号不能为空." if item["no"].blank?
        #messages << "服务开始时间不能为空." if item["begin"].blank?
        #messages << "服务结束时间不能为空." if item["end"].blank?
        unless item["no"].blank?
          service = ServiceItem.find_by_no(item["no"])
          messages << "服务#{item['no']}无法找到." if service.nil?
        end
      end
    end

    messages
  end

  def validate_delete_data(data)
    messages = []

    messages << "CID不能为空." if data["cid"].blank?

    unless data["cid"].blank?
      profile = ClientApiProfile.find_by_cid(data["cid"])
      messages << "CID不合法或者已被禁用." if profile.nil? || profile.disabled
    end

    messages << "客户编号不能为空." if data["no"].blank?

    messages
  end
end