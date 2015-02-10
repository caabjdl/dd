# encoding: utf-8
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable, :rememberable
  include Searchable

  attr_accessor :login
  devise :database_authenticatable, :registerable, :lockable,
         :recoverable, :trackable, :validatable, :authentication_keys => [:login]
  validates_presence_of :no
  validates_uniqueness_of :no
  validates :auto_assign_interval, numericality: { only_integer: true, greater_than: -1 }
  validate :validate_vendor_user
  has_one :aa_worker
  has_many :underlings, :class_name => "User", :foreign_key => "manager_id"
  belongs_to :manager, :class_name => "User", :foreign_key => "manager_id"
  belongs_to :aa_vendor
  has_and_belongs_to_many :user_handle_client_services, :class_name => "ClientService"
  has_and_belongs_to_many :settlement_institutions
  has_many :user_handle_districts
  has_and_belongs_to_many :user_handle_aa_vendors, :class_name => "AaVendor"
  accepts_nested_attributes_for :user_handle_districts, allow_destroy: true
  has_and_belongs_to_many :aa_vendors_accounts, :class_name => "AaVendor", :join_table => "aa_vendors_accounts", :foreign_key => "user_id", :association_foreign_key => "aa_vendor_id"
  before_save :set_aa_vendor,:clean_settlement_institutions

  scope :unlocked, -> { where("locked_at is  null")}
  scope :filter_roles, -> { where("role not in (?)",OPTIONS["user_disabled_by_role"]) }
  paginates_per 20

  quick_search :no, :name, :email, :department, :online_status, :role, :account_type

  def login=(login)
    @login = login
  end

  def validate_vendor_user
    if self.account_type == '直派供应商'
      if self.user_handle_aa_vendor_ids.count == 0
        errors.add("直派供应商账户", "必须添加调度供应商")
      end
    end
  end

  def set_status(status)
    self.online_status = status
    self.online_status_changed_at = Time.now
    self.save
  end
  
  def set_aa_vendor
    if self.account_type == '直派供应商'
      self.aa_vendor = self.user_handle_aa_vendors.first if self.user_handle_aa_vendors
    else
      self.aa_vendor = AaVendor.find_by_id(OPTIONS["system_vendor_id"])
    end
  end

  def clean_settlement_institutions
     settlements = self.settlement_institutions.where("client_service_id not in (?)",self.user_handle_client_service_ids)
     settlements.each do |item|
      self.settlement_institutions.delete(item)
     end
  end

  def login
    unless @login
      if self.no
        self.no
      else
        self.email
      end
    else
      @login
    end
  end

  def active_for_authentication? 
    super && !is_disabled?
  end 

  def inactive_message
    if is_disabled?
      :disabled
    else 
      super # Use whatever other message 
    end 
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["(lower(no) = :value OR lower(email) = :value)", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  class << self
    def current_user=(user)
      Thread.current[:current_user] = user
    end

    def current_user
      Thread.current[:current_user]
    end
  end

end
