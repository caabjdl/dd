#encoding utf-8
class AaVendor < ActiveRecord::Base
  include Sequenable
  include Disable
  include Searchable
  validates_presence_of :name, :address, :contact, :no
  validates_uniqueness_of :name, :no
  validates_numericality_of :trail_base_fare, :trail_include_kilometers, :trail_unit_price, :rescue_base_fare, :rescue_include_kilometers, :rescue_unit_price, allow_nil: true

  has_many :aa_trailers
  has_many :aa_contacts
  has_many :aa_regions
  has_many :aa_workers
  has_many :aa_vendor_attachments

  sequence :VE
  quick_search :address, :name, :mobile, :telephone, :contact

  accepts_nested_attributes_for :aa_trailers, allow_destroy: true
  accepts_nested_attributes_for :aa_contacts, allow_destroy: true
  accepts_nested_attributes_for :aa_regions, allow_destroy: true
  accepts_nested_attributes_for :aa_workers, allow_destroy: true
  accepts_nested_attributes_for :aa_vendor_attachments, allow_destroy: true
  has_and_belongs_to_many :aa_vendors_accounts, :class_name => "User", :join_table => "aa_vendors_accounts", :foreign_key => "aa_vendor_id", :association_foreign_key => "user_id"

  before_save :create_accounts
  

  paginates_per 20


  has_paper_trail
  scope :available, -> { where("aa_vendors.status = '可用' ") }
  scope :filter, ->(column_name, value, page) { where("? like ?",column_name, "%#{value}%").limit(page) }
  scope :high_search, ->(province,city,region) {joins(:aa_regions).where('(aa_regions.province = :province or :province = :empty) and (aa_regions.city = :city or :city = :empty) and (aa_regions.district = :district or :district = :empty)',{:province => province,:city => city,:district => region,:empty => ''})}
  scope :search_by_account, ->(user_id) {joins(:aa_vendors_accounts).where('(aa_vendors_accounts.user_id = :user_id )',:user_id => user_id)}

  default_scope { order('id desc') } 

  validate :validate_accounts
  def validate_accounts
    id_nos = []
    self.aa_workers.each do |worker|
      if id_nos.include?(worker.id_no)
        errors.add(:司机, "工号身份证 %s重复" % worker.id_no)
      end
      id_nos.push(worker.id_no)
    end
  end
  #TODO: 代码重构到User
  def create_accounts
    self.aa_workers.each do |worker|
      user = User.new
      if User.where(:no => worker.id_no).exists?
        user = User.where(:no => worker.id_no).first
      else
        user.role = '救援工'
        user.password = '12345678'
        user.password_confirmation = '12345678'
        user.department = ''
      end

      user.name = worker.name
      user.no = worker.id_no
      user.email = worker.id_no + "@caa.com.cn"
      user.save
      worker.user = user
    end
  end

  def online_aa_workers
    self.aa_workers.joins(:user).where("users.online_status = '空闲'")
  end

  def vendor_level(province,city,region,rescue_type)
    aa_region = self.aa_regions.where(province: province,city:city,district: region).first
    if aa_region && ["现场抢修","接电服务","更换轮胎","紧急送油","紧急加水","取送备用钥匙","开锁"].include?(rescue_type)
      return aa_region.support_level
    elsif aa_region && ["拖车牵引","吊装救援","事故车拖带","地库拖车"].include?(rescue_type)
      return aa_region.car_level
    end
    return ""
  end

  def get_help_telephone(province, city, district)
    region = AaRegion.where(:aa_vendor_id => self.id,:province =>province,:city=> city,:district=>district).first
    phone = self.help_telephone
    if region
      phone = region.telephone
    end
    return phone
  end

  def self.vendors_by_region(from_province,from_city,from_region)
    vendors = AaVendor.joins(:aa_regions).available.where('aa_regions.province = ? and aa_regions.city = ? and aa_regions.district = ? ',from_province,from_city,from_region)

    if User.current_user.user_handle_aa_vendors.length > 0
      vendors = vendors & User.current_user.user_handle_aa_vendors.available 
    end
    return vendors
  end

  def aa_vendor_region_fixed_price
    array = ""
    fixed_price_regions = self.aa_regions.where(fixed_price: "是")
    fixed_price_regions.each do |region|
      array +=  region.province + "-" + region.city + "-" + region.district + ","
    end
    if array.blank?
      array = "无"
    end
    return array
  end
end
