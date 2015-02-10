module Assignable
  extend ActiveSupport::Concern

  # usage has :owner, :operator 
  module ClassMethods
    def has(*names)
      names.each do |name|
        belongs_to name, class_name: :User
        belongs_to "#{name}_aa_vendor".to_sym, :class_name => "AaVendor", :foreign_key => "#{name}_aa_vendor_id"

        scope "filter_by_#{name}", ->(user) { where("#{name}_id = :user or #{name}_no = :user", user: user) }

        define_method "assign_#{name}" do |user|
          self.send("#{name}=", user)
          self.send("#{name}_id=", user.id)
          self.send("#{name}_no=", user.no)

          if user.aa_vendor
            self.send("#{name}_aa_vendor=",user.aa_vendor)
            self.send("#{name}_aa_vendor_id=",user.aa_vendor.id)
          end
        end
      end
    end
  end
end