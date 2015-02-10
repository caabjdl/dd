class District < ActiveRecord::Base
  include Searchable
  quick_search :province, :city, :region

  validates_presence_of :province,:city,:region

  validates_uniqueness_of :region

  paginates_per 10

  def self.provinces(name = nil)
    list = District.where("city is null or city = ''")
    unless name.nil?
      list = list.where("province like :name", :name => "%#{name}%")
    end
    [""].concat(list.distinct.pluck(:province))
  end

  def self.cities(province, name = nil)
    list = District.where(:province => province).where("(region is null or region = '') and (city is not null and city <> '')")
    unless name.nil?
      list = list.where("city like :name", :name => "%#{name}%")
    end
    [""].concat(list.distinct.pluck(:city))
  end

  def self.regions(province, city, name = nil)
    list = District.where(:province => province, :city => city).where("region is not null and region <> ''")
    unless name.nil?
      list = list.where("region like :name", :name => "%#{name}%")
    end
    [""].concat(list.distinct.pluck(:region))
  end
end
