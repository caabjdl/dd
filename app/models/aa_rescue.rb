#encoding: utf-8
class AaRescue < ActiveRecord::Base
  include Sequenable
  include Assignable
  include ActiveModel::Dirty

  attr_accessor :callback_for_pingan, :stat_array_for_pingan, :send_clam_flag

  has :creater, :owner
  sequence :RE

  # association
  belongs_to :aa_trailer
  belongs_to :aa_worker
  belongs_to :aa_case
  belongs_to :client
  has_many :aa_rescue_attachments
  belongs_to :aa_vendor
  has_many :aa_case_logs
  has_one :accounting_job
  has_many :worker_jobs, autosave: true
  accepts_nested_attributes_for :aa_case_logs
  accepts_nested_attributes_for :aa_case

  # callback
  before_save :log, :set_status, :init_worker_job, :set_aa_vendor_name
  after_save :logic_for_pingan, :send_msg_to_customer, :set_send_flag
  after_commit :execute_logic_for_pingan,:send_msg_to_worker
  after_commit :notify_for_common_api
  # validate
  validate :validate_columns_for_pingan
  validate :validate_completed#,:validate_aa_vendor
  validates_presence_of :canceled_at, if: Proc.new { |a| !a.distance_empty_run.blank? && a.distance_empty_run > 0 }  
  validates_presence_of :cancel_reason, if: Proc.new { |a| !canceled_at.nil? }  
  validates_presence_of :aa_vendor_id, if: Proc.new { |a|  !a.dispatched_at.nil? }
  validates_presence_of :aa_vendor_name, if: Proc.new { |a| !a.aa_vendor.nil? && a.aa_vendor.name.include?("临时供应商")}
  has_paper_trail
  
  default_scope { order('id desc') }

  def init(aa_case, user)
    set_aa_case(aa_case)
    aa_case.assign_owner(user)
    aa_case.assign_dispatcher(user)
    self
  end

  def set_aa_vendor_name
    if !self.aa_vendor.nil? && ( !self.aa_vendor.name.include?("临时供应商") && !self.aa_vendor.name.include?("未登记"))
      self.aa_vendor_name = self.aa_vendor.name
    end
  end

  def assign_worker(user)
    #assign aa_vendor
    if user.user_handle_aa_vendors.count == 1
      aa_vendor = user.user_handle_aa_vendors.first
      self.aa_vendor = aa_vendor
      self.save(validate:false)
      #TODO: 处理分配worker
      #assign worker
      # aa_worker = aa_vendor.aa_workers.joins(:user).where("users.online_status = '空闲'").first
      # if aa_worker
      #   self.aa_worker = aa_worker
      #   self.save(validate:false)
      # end
    end
  end

  def can_deployed_aa_workers
    if self.aa_vendor && self.aa_worker
      self.aa_vendor.online_aa_workers.include?(self.aa_worker) ? self.aa_vendor.online_aa_workers : self.aa_vendor.online_aa_workers.unshift(self.aa_worker)
    elsif self.aa_vendor
      self.aa_vendor.online_aa_workers
    end
  end

  def log
    self.aa_case_logs.each do |log| 
      if log.new_record?
        log.logger_id = User.current_user.id
        log.log_at = Time.now unless log.log_at
        #self.aa_case.status = log.status if log.status
        self.aa_case.aa_case_logs << log
        self.aa_case.save
      end
    end
  end

  def set_status
    if !self.contacted_at.nil? && self.dispatched_at.nil? && self.plan_arrive_at.nil? && self.arrived_at.nil? && self.completed_at.nil? && self.canceled_at.nil?
      self.status = "已回拨"
    elsif !self.dispatched_at.nil? && self.completed_at.nil? && self.canceled_at.nil?
      self.status = "已调度救援中"
    elsif !self.completed_at.nil? && self.canceled_at.nil? && !self.satisfaction.blank?
      self.status = "已完成"
    elsif !self.canceled_at.nil? && (self.distance_empty_run.nil? || self.distance_empty_run == 0)
      self.status = "取消无空驶"
    elsif !self.canceled_at.nil? && self.distance_empty_run > 0
      self.status = "取消有空驶"
    else
      if !self.status
        self.status = ""
      end
    end

    if !self.status.blank?
      self.aa_case.status = self.status
      self.aa_case.save(:validate=>false)
    end
  end

  def set_send_flag
    self.send_clam_flag = self.worker_jobs.enabled.first && (self.aa_worker_id_changed? || self.worker_jobs.enabled.first.new_record?)
  end

  def send_msg_to_worker
    if self.send_clam_flag
      ClamApiWorker.perform_async(self.id)
      if self.aa_worker.can_send_sms
        SmsApiWorker.perform_async("remind_worker",self.aa_case.id)
      end
      self.worker_jobs.enabled.first.owner.set_status('繁忙') if self.worker_jobs.enabled.first
    end
  end

  def send_msg_to_customer
    if self.status_changed? && self.status == '已调度救援中' && self.aa_vendor
      send_msg("customer_dispatched")
    elsif self.status_changed? && self.status == '已完成' && self.aa_vendor
      send_msg("customer_visited")
    end
  end

  def send_msg(method)
    client_service = ClientService.where(name:self.aa_case.client_service_name).first
    service_item = ServiceItem.where(name:self.aa_case.rescue_type).first

    if client_service && service_item && client_service.can_send_sms && service_item.can_send_sms
      SmsApiWorker.perform_async(method,self.aa_case.id)
    end
  end

  def init_worker_job
    if self.aa_worker
      new_worker_job
    else
      disabled_worker_job
    end
  end

  def new_worker_job
    active_worker_job = self.worker_jobs.enabled.first
      # 当前启用worker_job的owner 不是aa_rescue的worker 或者 worker_job没有时 需要new
    is_not_active_aa_worker_job = active_worker_job && self.aa_worker.user.no != active_worker_job.owner.no
    if active_worker_job.nil? || is_not_active_aa_worker_job
      if active_worker_job
        disabled_worker_job
      end
      active_worker_job = WorkerJob.new
    end
    active_worker_job.set_data(self)
    self.worker_jobs << active_worker_job if active_worker_job.new_record?
  end

  def disabled_worker_job
    self.worker_jobs.enabled.each do |worker_job|
      worker_job.disable
      worker_job.save
    end
  end

  def is_create_accounting_job
    ['已完成','取消有空驶','取消无空驶'].include?(self.status) && !self.aa_vendor.nil?
  end
  
  def self.search(customer_mobile, customer_name, car_license_no)
    if customer_mobile
      where('aa_cases.customer_mobile = ?', customer_mobile)
    elsif customer_name
      where('aa_cases.customer_name = ?', customer_name)
    elsif car_license_no
      where('aa_cases.car_license_no = ?', car_license_no)
    end
  end

  # 平安API逻辑
  def logic_for_pingan
    self.callback_for_pingan = false
    self.stat_array_for_pingan = nil
    if self.aa_case.data_source == "平安接口" && need_send_operation?
      self.callback_for_pingan = true
      self.stat_array_for_pingan = get_stats_queue_for_pingan
    end
  end

  def execute_logic_for_pingan
    if self.callback_for_pingan
      PinganApiWorker.perform_async(:send_operation, { aa_rescue_id: self.id, stats_array: self.stat_array_for_pingan })
      self.callback_for_pingan = false
      self.stat_array_for_pingan = nil
    end
  end

  def total_distance
    return self.distance_arrive.to_f + self.distance_drag.to_f + self.distance_empty_run.to_f + self.distance_back.to_f 
  end

  def accounting_price
    total_price = 0
    aa_case = AaCase.find(self.aa_case_id)
    vendor = AaVendor.find(self.aa_vendor_id)
    service_item = ServiceItem.find_by(name: aa_case.rescue_type)

    if service_item
      if service_item.category == "救援"
        total_price += self.distance_arrive.to_f * vendor.rescue_unit_arrive.to_f
        total_price += self.distance_drag.to_f * vendor.rescue_unit_drag.to_f
        total_price += self.distance_back.to_f * vendor.rescue_unit_back.to_f
        total_price += self.distance_empty_run.to_f * vendor.rescue_unit_empty_run.to_f
      else
        total_price += self.distance_arrive.to_f * vendor.trail_unit_arrive.to_f
        total_price += self.distance_drag.to_f * vendor.trail_unit_drag.to_f
        total_price += self.distance_back.to_f * vendor.trail_unit_back.to_f
        total_price += self.distance_empty_run.to_f * vendor.trail_unit_empty_run.to_f
      end
    else
      total_price += self.distance_arrive.to_f * vendor.trail_unit_arrive.to_f
      total_price += self.distance_drag.to_f * vendor.trail_unit_drag.to_f
      total_price += self.distance_back.to_f * vendor.trail_unit_back.to_f
      total_price += self.distance_empty_run.to_f * vendor.trail_unit_empty_run.to_f
    end

    return total_price
  end

  def once_price
    total_once_price = 0
    aa_case = AaCase.base_scope.find(self.aa_case_id)
    vendor = AaVendor.find(self.aa_vendor_id)
    service_item = ServiceItem.find_by(name: aa_case.rescue_type)

    if service_item
      if service_item.category == "救援"
        total_once_price = vendor.rescue_base_fare.to_f
      else 
        total_once_price = vendor.trail_base_fare.to_f
      end
    else
      total_once_price = vendor.trail_base_fare.to_f
    end

    return total_once_price
  end

  def tracking
    start_time = Time.now.strftime('%Y%m%d')
    end_time = (Time.now + 1.day).strftime('%Y%m%d')
    start_time = self.dispatched_at.strftime('%Y%m%d') unless self.dispatched_at.blank?
    end_time = self.plan_arrive_at.strftime('%Y%m%d') unless self.plan_arrive_at.blank?
    tracking_back = MirrtalkApi::Services::Geo.instance.get_path(self.aa_worker.aa_trailer.device.device_account_id, start_time, end_time)
    # tracking_back = MirrtalkApi::Services::Geo.instance.get_path("lgyvq1Kllc", start_time, end_time)

    data_array = []
    coords = []

    unless tracking_back.blank?
      tracking_back.sort! { |x, y| y["startTime"].to_i <=> x["startTime"].to_i }

      tracking_back.each do |item|
        slng = item["startLongitude"]
        slat = item["startLatitude"]
        elng = item["endLongitude"]
        elat = item["endLatitude"]

        coords << slng + "," + slat 
        coords << elng + "," + elat 
      end
      baidu_coords = GeoApi.coord_to_baidu("#{coords.join(';')}", "1", "5")
      unless baidu_coords.nil?
        baidu_coords.each_with_index do |coord, index|
          data_back = Hash.new
          data_back["Longitude"] = coord["x"]
          data_back["Latitude"] = coord["y"]
          data_array << data_back
        end
      end
    end

    return data_array.to_json
  end


  private
  
  def set_aa_case(aa_case)
    self.aa_case = aa_case
  end

  def set_aa_worker(aa_worker)
    self.aa_worker = aa_worker
    self.aa_worker_name = aa_worker.name
  end

  def need_send_operation?
    return (self.contacted_at_changed? && self.contacted_at_was != self.contacted_at) ||
      (self.dispatched_at_changed? && self.dispatched_at_was != self.dispatched_at) ||
      (self.arrived_at_changed? && self.arrived_at_was != self.arrived_at) ||
      (self.plan_arrive_at_changed? && self.plan_arrive_at_was != self.plan_arrive_at) ||
      (self.completed_at_changed? && self.completed_at_was != self.completed_at) ||
      (self.canceled_at_changed? && self.canceled_at_was != self.canceled_at) ||
      (self.cancel_reason_changed? && !self.cancel_reason.blank?)
  end

  def validate_completed
    if !self.completed_at.nil? and distance_arrive.nil? and distance_back.nil? and distance_empty_run.nil?
        errors.add(:completed_at, "至少输入一个里程.")
    end  
  end

  def validate_aa_vendor
    if self.aa_vendor.nil? 
      errors.add(:aa_vendor_id,"请选择或者输入供应商")
    end
  end

  def validate_columns_for_pingan
    if self.aa_case.data_source == "平安接口" && need_send_operation?
      stats_queue = get_stats_queue_for_pingan
      stats_queue.each do |stats|
        if stats == "1"
          errors.add(:aa_worker_name, "不能为空.") if self.aa_worker_name.blank?
          errors.add(:aa_worker_phone, "不能为空.") if self.aa_worker_phone.blank?
          errors.add(:plan_arrive_at, "不能为空.") if self.plan_arrive_at.nil? 
        end
        if stats == "2"
          errors.add(:rescue_reason, "不能为空.") if self.aa_case.rescue_reason.blank?
          errors.add(:completed_at, "不能为空.") if self.completed_at.nil?
          errors.add(:from_details, "不能为空.") if self.aa_case.from_details.blank?
        end
      end
    end
  end

  def get_stats_queue_for_pingan
    queue = Array.new

    # 如果变更了“回拨时间”且“回拨时间不为空”发送状态8
    if self.contacted_at_changed? && self.contacted_at_was != self.contacted_at && !self.contacted_at.nil?
      queue << "8"
    end

    # 如果变更了“调派时间”或“预计达到”或“实际达到”且变更后不为空，发送状态1
    if (self.dispatched_at_changed? && self.dispatched_at_was != self.dispatched_at && !self.dispatched_at.nil?) ||
      (self.plan_arrive_at_changed? && self.plan_arrive_at_was != self.plan_arrive_at && !self.plan_arrive_at.nil?) ||
      (self.arrived_at_changed? && self.arrived_at_was != self.arrived_at && !self.arrived_at.nil?)
      queue << "1"
    end

    # 如果变更了“实际完成”且“实际完成”不为空，发送状态2
    if self.completed_at_changed? && self.completed_at_was != self.completed_at && !self.completed_at.nil?
      queue << "2"
    end

    # 如果变更了“取消时间”且“取消时间”不为空 || 如果变更了“取消原因”且“取消原因”不为空
    if (self.canceled_at_changed? && self.canceled_at_was != self.canceled_at && !self.canceled_at.nil?) ||
      (self.cancel_reason_changed? && !self.cancel_reason.blank?)
      # 如果取消原因中含有“无能力”，发送状态73
      if self.cancel_reason.include? "能力不足"
        queue << "73"
      # 如果取消原因中含有“未救援”，发送状态3
      # elsif self.cancel_reason.include? "未调派"
      #   queue << "4"
      # 其他情况下，发送状态4
      else
        queue << "4"
      end
    end

    # 如果变更了”取消时间”且“取消时间”为空，发送状态1并清空”取消原因“
    if self.canceled_at_changed? && self.canceled_at_was != self.canceled_at && self.canceled_at.nil?
      queue << "1"

      # 如果“实际完成“不为空，再发送状态2
      unless self.completed_at.nil?
        queue << "2"
      end
    end

    queue
  end

  def notify_for_common_api
    if self.aa_case.data_source == "通用接口" || self.aa_case.customer
      CommonSalvationApiService.instance.salvation_callback(self.aa_case)
    end
  end



end
