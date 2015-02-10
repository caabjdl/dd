class WorkerJob < ActiveRecord::Base
  include Assignable
  include Disable

  has_many :wechat_medias, class_name: 'Wechat::WechatMedia'
  has_many :wechat_locations, class_name: 'Wechat::WechatLocation'
  belongs_to :aa_rescue
  belongs_to :aa_case
  has :owner

  def set_data(aa_rescue)
    self.aa_case_no = aa_rescue.aa_case.no
    self.aa_case_id = aa_rescue.aa_case.id
    self.owner_id = aa_rescue.aa_worker.user.id if aa_rescue.aa_worker.user
    self.owner_no = aa_rescue.aa_worker.user.no if aa_rescue.aa_worker.user
    self.customer_name = aa_rescue.aa_case.customer_name
    self.customer_mobile = aa_rescue.aa_case.customer_mobile
    self.car_license_no = aa_rescue.aa_case.car_license_no
    self.car_vin = aa_rescue.aa_case.car_vin
    self.car_model = aa_rescue.aa_case.car_model
    self.car_color = aa_rescue.aa_case.car_color
    self.rescue_type = aa_rescue.aa_case.rescue_type
    self.rescue_reason = aa_rescue.aa_case.rescue_reason
    self.from_province = aa_rescue.aa_case.from_province
    self.from_city = aa_rescue.aa_case.from_city
    self.from_region = aa_rescue.aa_case.from_region
    self.from_details = aa_rescue.aa_case.from_details
    self.to_province = aa_rescue.aa_case.to_province
    self.to_city = aa_rescue.aa_case.to_city
    self.to_region = aa_rescue.aa_case.to_region
    self.to_details = aa_rescue.aa_case.to_details
  end

  def call_status_back_to_rescue
    case self.status
    when '已到达'
      self.aa_rescue.arrived_at = self.arrived_at
    when '已完成'
      self.aa_rescue.completed_at = self.completed_at
    when '已取消'
      self.aa_rescue.canceled_at = self.canceled_at
    end
    self.aa_rescue.save(validate: false)
  end

  def tracking_data
    origin_tracking_data = self.wechat_locations.pluck(:latitude,:longitude).uniq
    tracking_data = []
    origin_tracking_data.each do |origin_gps|
      mars_result = GoToMars.land_at(origin_gps[0].to_f, origin_gps[1].to_f)
      tracking_data << mars_result
    end
    return tracking_data
  end
end
