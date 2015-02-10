jQuery(document).ready(function() {

  $("#aa_rescue_aa_case_attributes_from_province").change(function(e){
    fillCities($("#aa_rescue_aa_case_attributes_from_province"), $("#aa_rescue_aa_case_attributes_from_city"));
  });

  $("#aa_rescue_aa_case_attributes_from_city").change(function(e){
    fillRegions($("#aa_rescue_aa_case_attributes_from_province"), $("#aa_rescue_aa_case_attributes_from_city"), $("#aa_rescue_aa_case_attributes_from_region"));
  });

  $("#aa_rescue_aa_case_attributes_to_province").change(function(e){
    fillCities($("#aa_rescue_aa_case_attributes_to_province"), $("#aa_rescue_aa_case_attributes_to_city"));
  });

  $("#aa_rescue_aa_case_attributes_to_city").change(function(e){
    fillRegions($("#aa_rescue_aa_case_attributes_to_province"), $("#aa_rescue_aa_case_attributes_to_city"), $("#aa_rescue_aa_case_attributes_to_region"));
  });
  
  $('#refer_aa_vendor').change(function(e){
    $("#aa_rescue_aa_vendor_id").select2('data',{id: $(this).val(), text: $(this).select2('data').text });
    $("#aa_rescue_aa_vendor_id").change();
  });

  $('#aa_rescue_aa_vendor_id').select2({
    placeholder: "请输入供应商名称",
    ajax: {
      url: "/ajax/aa_vendors/list_by_name",
      quietMillis: 1000,
      data: function(keywords){
        return {
          name: keywords
        }
      },
      results: function(data){
        list = [];
        $.each(data, function(index, item){
          if (item.aa_vendor_type!=null && item.aa_vendor_type == "三天") {
            list.push({ id: item.id, text: item.name + "("+item.aa_vendor_type+")" });
          }
          else{
            list.push({ id: item.id, text: item.name });
          }
          
        });
        return {
          results: list
        }
      }
    },
    initSelection: function (element, callback){
      var id = $(element).val();
      if (id !== ""){
        $.ajax("/ajax/aa_vendors/" + id).done(function (data){
          var data_show;
          if (data.aa_vendor_type == "三天") {
            data_show = { id: data.id, text: data.name+"("+data.aa_vendor_type+")" };
          }
          else{
            data_show = { id: data.id, text: data.name};
          }
          callback(data_show);
        });
      }
    }
  }).change(function(e){
    $("#aa_rescue_aa_vendor_name").val($(this).select2('data').text);
  });
  

 $("#aa_rescue_aa_vendor_id").change(function(e){
      $.ajax({
        url: "/ajax/aa_vendors/workers?id=" + $(this).val()+"&province="+$("#aa_rescue_aa_case_attributes_from_province").val()+"&city="+$("#aa_rescue_aa_case_attributes_from_city").val()+"&district="+$("#aa_rescue_aa_case_attributes_from_region").val()
      }).done(function(data){
        $("#aa_rescue_aa_worker_id").empty();
        $("#aa_rescue_aa_worker_id").select2("data", null);
        $("#aa_rescue_aa_worker_id").append(new Option(""));
        $(data.workers).each(function(index, item){
          $("#aa_rescue_aa_worker_id").append(new Option(item.name,item.id));
        });
        // $("#aa_rescue_aa_worker_id").change();
        $("#help_telephone").val(data.phone);
        $(data.trailers).each(function(index, item){
          $("#aa_rescue_aa_trailer_id").append(new Option(item.license_no,item.id));
        });
      });
  });

  $("#aa_rescue_aa_worker_id").change(function(e){
      $("#aa_rescue_aa_worker_name").val($(this).select2('data').text);
      $.ajax({
        url: "/ajax/aa_workers/" + $(this).val()
      }).done(function(data){
        if (data!=null) {
          $("#aa_rescue_aa_worker_phone").val(data.mobile);
        };
      });
  });

  $("#sms_send").click(function(e){
    event.preventDefault();
    $.get($(this).attr('href') + "?sms_phone=" + $('#sms_phone').val(), function(data){} );
  });

  //地图
  $("#show_from").click(function(e){
    address = "";
    $.each(['province','city','region','details'],function(i,item){
      address += $('#aa_rescue_aa_case_attributes_from_' + item).val();
    });
    var x = $("#aa_rescue_aa_case_attributes_from_longitude").val();
    var y = $("#aa_rescue_aa_case_attributes_from_latitude").val();
    openwindow('/aa_cases/map?address='+address+'&x='+x+'&y='+y, '', '900', '600')
    //window.showModalDialog ('/aa_cases/map',address,'help:no;scroll:no;resizable:no;status:0;dialogWidth:900px;dialogHeight:600px;center:yes') 
  });

  $("#show_to").click(function(e){
    address = "";
    $.each(['province','city','region','details'],function(i,item){
      address += $('#aa_rescue_aa_case_attributes_to_' + item).val();
    });
    openwindow('/aa_cases/map?address='+address, '', '900', '600')
    //window.showModalDialog ('/aa_cases/map',address,'help:no;scroll:no;resizable:no;status:0;dialogWidth:900px;dialogHeight:600px;center:yes') 
  });

  $("#show_tracking").click(function(e){
    var action = $(this).attr("name");
    openwindow(action, '', '900', '600')
    //window.showModalDialog(action,'','help:no;scroll:no;resizable:no;status:0;dialogWidth:900px;dialogHeight:600px;center:yes')
  });

  $("#history_by_phone").mouseover(function(e){
    if($("#badge_customer_mobile").html()=="?")
    {
      fill_history_count_by_phone($("#aa_rescue_aa_case_attributes_customer_mobile").val());
    }
  });

  $("#history_by_license_no").mouseover(function(e){
    if($("#badge_car_license_no").html()=="?")
    {
      fill_history_count_by_license_no($("#aa_rescue_aa_case_attributes_car_license_no").val());
    }
  });
  $("#history_by_car_vin").mouseover(function(e){
    if($("#badge_car_vin").html()=="?")
    {
      fill_history_count_by_car_vin($("#aa_rescue_aa_case_attributes_car_vin").val());
    }
  });

  $("#aa_rescue_aa_case_attributes_customer_mobile").change(function(){
    fill_history_count_by_phone($(this).val());
  });

  $("#aa_rescue_aa_case_attributes_car_license_no").change(function(){
    fill_history_count_by_license_no($(this).val());
  });
  $("#aa_rescue_aa_case_attributes_car_vin").change(function(){
    fill_history_count_by_car_vin($(this).val());
  });

  if($('#show_cancel_modal').val() == 'true')
  {$('#wait_cancel').modal('show');}
  
});

function fill_history_count_by_phone(value){
  $.ajax({
    url: $("#history_by_phone").data("remote-url") + "&phone=" + value
  }).done(function(data){
    if (data == "0"){
      $("#badge_customer_mobile").attr("class", "badge badge-default").html("0");
    }else{
      $("#badge_customer_mobile").attr("class", "badge badge-danger").html(data);
    }
  });
}

function fill_history_count_by_license_no(value){
  $.ajax({
    url: $("#history_by_license_no").data("remote-url") + "&license_no=" + value
  }).done(function(data){
    if (data == "0"){
      $("#badge_car_license_no").attr("class", "badge badge-default").html("0");
    }else{
      $("#badge_car_license_no").attr("class", "badge badge-danger").html(data);
    }
  });
}

function fill_history_count_by_car_vin(value){
  $.ajax({
    url: $("#history_by_car_vin").data("remote-url") + "&car_vin=" + value
  }).done(function(data){
    if (data == "0"){
      $("#badge_car_vin").attr("class", "badge badge-default").html("0");
    }else{
      $("#badge_car_vin").attr("class", "badge badge-danger").html(data);
    }
  });
}