jQuery(document).ready(function() {

  $('form').on('click', '.remove_fields', function(e){
    $(this).prev('input[type=hidden]').val('1');
    $(this).closest('tr').hide();

    documentSizeChanged();
    return e.preventDefault();
  });

  $('form').on('click', '.add_fields', function(e){
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');

    $(this).closest('tr').before($(this).data('fields').replace(regexp, time));

    documentSizeChanged();
    
    $(this).closest('tr').prev('tr').find('.select2me').select2({
      placeholder: "请选择",
      allowClear: true
    });

    $(this).closest('tr').prev('tr').find('.date-picker').datepicker({
      format: "yyyy-mm-dd",
      autoclose: true
    });

    return e.preventDefault();
  });

  $("button[type=submit]").click(function(e){
    $(this).attr("disabled", "disabled");
    $(this).closest("form").submit();
  });

  $('form').on('click', '.add_row', function(e){
    $(this).closest('tr').before($(this).data('fields'));
    documentSizeChanged();
    return e.preventDefault();
  });

  $('form').on('click', '.remove_row', function(e){
    $(this).closest('tr').remove();
    documentSizeChanged();
    return e.preventDefault();
  });
});

function fillProvinces(province_control){
  $.ajax({
    url: "/ajax/districts/provinces"
  }).done(function(data){
    $(province_control).empty();
    $(province_control).select2("data", null);
    $(data).each(function(index, item){
      $(province_control).append(new Option(item));
    });
    $(province_control).change();
  });
}

function fillCities(province_control, city_control){
  $.ajax({
    url: "/ajax/districts/cities?province=" + $(province_control).val()
  }).done(function(data){
    $(city_control).empty();
    $(city_control).select2("data", null);
    $(data).each(function(index, item){
      $(city_control).append(new Option(item));
    });
    $(city_control).change();
  });
}

function fillRegions(province_control, city_control, region_control){
  $.ajax({
    url: "/ajax/districts/regions?province=" + $(province_control).val() + "&city=" + $(city_control).val()
  }).done(function(data){
    $(region_control).empty();
    $(region_control).select2("data", null);
    $(data).each(function(index, item){
      $(region_control).append(new Option(item));
    });
    $(region_control).change();
  });
}

function documentSizeChanged(){
  $(".form-actions").css("position", "static");
  offset_init = $(window).height() - $(".footer").outerHeight() - $(".form-actions").outerHeight() - $(".form-actions").offset().top;

  $(".form-actions").css("position", "relative")
                    .css("top", $(window).scrollTop() + offset_init);
}

function fillAssignOwners(aa_case_id, control){
  $.ajax({
    url: "/ajax/users/assign_by_aa_case?aa_case_id=" + aa_case_id
  }).done(function(data){
    $(control).empty();
    $(control).select2("data", null);
    $(data).each(function(index, item){
      $(control).append(new Option(item.name, item.id));
    });
    $(control).change();
    $.uniform.update(control);
  });
}

function openwindow(url, name, iwidth, iheight){
  var itop = (window.screen.height - 30 - iheight) / 2;
  var ileft = (window.screen.width - 10 - iwidth) / 2;
  window.open(url, name, 'height='+ iheight +',width='+ iwidth +',top='+ itop +',left='+ ileft +',toolbar=no,menubar=no,scrollbars=auto,resizeable=no,location=no,status=no');
}

function getUrlParams(){
  var args = new Object();   
  var query = location.search.substring(1);
  var pairs = query.split("&");
  for(var i = 0; i < pairs.length; i++){
    var pos = pairs[i].indexOf('=');
    if(pos == -1) continue; 
    var argname = pairs[i].substring(0,pos);
    var value = pairs[i].substring(pos + 1);
    args[argname] = unescape(value);
  }
  return args;
}