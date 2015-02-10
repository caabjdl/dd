class CustomFormBuilder < ActionView::Helpers::FormBuilder

  def c_text_field(label, *args)
    options = args.extract_options!
    new_class = options[:class] || "form-control"
    new_value = options[:value] || object.send(label)
    @template.text_field(object_name, label, *(args << options.merge(:class => new_class, :value => new_value)))
  end

  def c_date_field(label, *args)
    options = args.extract_options!
    new_class = options[:class] || "form-control"
    new_value =  object.send(label).strftime('%Y-%m-%d') if object.send(label)
    @template.content_tag(:div, :class => "input-group input-medium date date-picker") do
      @template.text_field(object_name, label, *(args << options.merge(:class => new_class, :value => new_value))) +
      @template.content_tag(:span, :class => "input-group-btn") do
        @template.button_tag(:class => "btn default date-set", :type => "button") do
          @template.content_tag(:i, :class => "fa fa-calendar") do
          end
        end
      end
    end
  end

  def c_datetime_field(label, *args)
    options = args.extract_options!
    new_class = options[:class] || "form-control"
    new_value =  object.send(label).strftime('%Y-%m-%d %H:%M:%S') if object.send(label)
    @template.content_tag(:div, :class => "input-group date form_datetime") do
      @template.text_field(object_name, label, *(args << options.merge(:class => new_class, :value => new_value))) +
      @template.content_tag(:span, :class => "input-group-btn") do
        @template.button_tag(:class => "btn default date-reset", :type => "button") do
          @template.content_tag(:i, :class => "fa fa-times") do
          end
        end
      end +
      @template.content_tag(:span, :class => "input-group-btn") do
        @template.button_tag(:class => "btn default date-set", :type => "button") do
          @template.content_tag(:i, :class => "fa fa-calendar") do
          end
        end
      end
    end
  end

  def error_messages
    if object.errors.full_messages.any?
      @template.content_tag(:div, :class => "alert alert-danger") do
        @template.content_tag(:strong, "错误") +
        @template.content_tag(:ul) do
          object.errors.full_messages.map do |msg|
            @template.content_tag(:li, msg)
          end.join.html_safe
        end
      end
    end
  end
end