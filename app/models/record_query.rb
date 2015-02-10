module RecordQuery
  def respond_to?(method_id, include_private = false)
    if method_id.to_s =~ /^like|between|equal_[\w]+$/
      true
    else
      super
    end
  end

  def method_missing(method_id, *arguments, &block)
    regex = /^like|between|equal_[\w]+$/
 
    if method_id.to_s =~ regex &&  self.column_names.include?(attribute_name = method_id.to_s.match(/_[\w]+$/)[0].gsub(/^_/,''))
      type = /^like|between|equal/.match(method_id.to_s)[0]
      case  type
      when 'like'
        return where(" #{attribute_name} like ? ", "%#{arguments[0]}%") unless arguments[0].blank?
      when 'between'
        sql = ''
        sql = sql + " %s > '%s' " % [attribute_name, arguments[0]] unless arguments[0].blank?
        sql = sql + " %s %s < '%s'" % [sql.blank? ? '' : 'and' , attribute_name, arguments[1]] unless arguments[1].blank?
        return where(sql) unless sql.empty?
      when 'equal'
        return where(" #{attribute_name} = ? ", "#{arguments[0]}") unless arguments[0].blank?
      end
       
      return where('')
    else
      super
    end
  end


end