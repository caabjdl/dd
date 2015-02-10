#encoding: utf-8
module Sequenable
  extend ActiveSupport::Concern
  module ClassMethods

    def sequence(prefix = nil)
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        after_initialize :generate_no
        validates_uniqueness_of :no

        private
        def generate_no
          # 如果序号为空,或者已经被锁定了,就重新创建一个序号
          file = File.open("tmp/locks/" + self.class.name.underscore.pluralize + "_no.lock", "w")
          file.flock(File::LOCK_EX)

          if self.no.blank?
            begin
              self.no = Time.now.strftime("#{prefix}%y%m%d%H%M%S%L")
            end until UniqueNumberManager.lock!(self.class.name.underscore.pluralize, "no", self.no, 1)
          end

          file.flock(File::LOCK_UN)
        end

      CODE
    end
  end
end