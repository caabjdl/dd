# encoding: utf-8
module ApplicationHelper
  ActionView::Base.default_form_builder = CustomFormBuilder

  def link_to_add_fields(name, f, association)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_fields btn default btn-xs black pull-right", data: { id: id, fields: fields.gsub("\n", "")})
  end

  def dynamic_table(sources)
    template = if DEPARTMENTSPROFILE[controller_name][action_name] && DEPARTMENTSPROFILE[controller_name][action_name].keys.include?(current_user.department) 
      DEPARTMENTSPROFILE[controller_name][action_name][current_user.department]
    else
      DEPARTMENTSPROFILE[controller_name][action_name] ? DEPARTMENTSPROFILE[controller_name][action_name]["default"] : 'default'
    end
    render("aa_cases/lists/" + template, :sources => sources)
  end

  def omission_td(length, *data)
    str = data.join('')
    omission_has = str.length > length
    omission_str = omission_has ? str[0,length]+'...' : str
    if omission_has
      content_tag(:td, :class => 'tooltips', :data => { :html =>true, :container=>'body', :placement=>'top', 'original-title' => str }) do
        omission_str
      end
    else
      content_tag(:td) do
        omission_str
      end
    end
  end

  def omission_td_rowspan(length, *data)
    str = data.join('')
    omission_has = str.length > length
    omission_str = omission_has ?  str[0,length]+'...' : str
    if omission_has
      content_tag(:td, :class => 'tooltips',:rowspan=>'2', :data => { :html =>true, :container=>'body', :placement=>'top', 'original-title' => str }) do
        omission_str
      end
    else
      content_tag(:td, :rowspan => '2') do
        omission_str
      end
    end
  end

  def tr_class(aa_case)
    cls = ""
    if aa_case.is_waiting_cancel
      cls = "success"
    elsif aa_case.owner.nil?
      cls = "danger"
    end
  end

  def loop_send(object, methods, num = 0 )
    unless object.send(methods[num]).nil?
      num < methods.length - 1 ? loop_send(object.send(methods[num]),methods,num = num + 1 ) : object.send(methods[num])   
    end  
  end

  def is_test_app
    File.exist?("#{Rails.root}/config/test_app.rb")
  end

  def is_query
    return !(current_user && OPTIONS["aa_cases_query_permission"].include?(current_user.role))
  end
end

