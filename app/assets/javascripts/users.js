jQuery(document).ready(function() {

  $('form').on('click', '#table_districts .add_fields', function(e) {

    var id = $(this).closest('tr').prev('tr').find('select.model_province').data("id");

    if (id != null){
      fillProvinces($("#user_user_handle_districts_attributes_" + id + "_province"));

      $(this).closest('tr').prev('tr').find('select.model_province').change(function(e){
        fillCities($("#user_user_handle_districts_attributes_" + id + "_province"), $("#user_user_handle_districts_attributes_" + id + "_city"));
      });

      $(this).closest('tr').prev('tr').find('select.model_city').change(function(e){
        fillRegions($("#user_user_handle_districts_attributes_" + id + "_province"), $("#user_user_handle_districts_attributes_" + id + "_city"), $("#user_user_handle_districts_attributes_" + id + "_region"));
      });
    }
  });

  $("#table_districts").find("tr").each(function(index, item){
    var id = $(item).find('select.model_province').data("id");
    if (id != null){
      $(item).find('select.model_province').change(function(e){
        fillCities($("#user_user_handle_districts_attributes_" + id + "_province"), $("#user_user_handle_districts_attributes_" + id + "_city"));
      });

      $(item).find('select.model_city').change(function(e){
        fillRegions($("#user_user_handle_districts_attributes_" + id + "_province"), $("#user_user_handle_districts_attributes_" + id + "_city"), $("#user_user_handle_districts_attributes_" + id + "_region"));
      });
    }
  });

  $('form').on('click', '#table_aa_vendors .add_row', function(e){
    loadAaVendor($(this).closest('tr').prev('tr').find("input.model_name"), $(this).closest('tr').prev('tr').find("input.model_id"));
  });
  $("#table_aa_vendors").find("tr").each(function(index, item){
    loadAaVendor($(item).find("input.model_name"), $(item).find("input.model_id"));
  });
  $("#select_all_client_services").click(function(){
    if ($(this).attr("checked")){
      $("[name='user[user_handle_client_service_ids][]']").each(function(){
        $(this).attr("checked", true);
        $.uniform.update(this);
      });
    } else {
      $("[name='user[user_handle_client_service_ids][]']").each(function(){
        $(this).attr("checked", false);
        $.uniform.update(this);
      });
    }
  });

  $("#select_all_settlements").click(function(){
    if ($(this).attr("checked")){
      $("[name='user[settlement_institution_ids][]']").each(function(){
        $(this).attr("checked", true);
        $.uniform.update(this);
      });
    } else {
      $("[name='user[settlement_institution_ids][]']").each(function(){
        $(this).attr("checked", false);
        $.uniform.update(this);
      });
    }
  });
});

function fillSettlements(client_service_id, control,ids,user_id){
  $.ajax({
    url: "/ajax/client_services/"+client_service_id+"/get_settlements?user_id="+user_id
  }).done(function(data){
    $(control).empty();
    $("#settlement_hiddens_div").empty();
    var html = "";
    $(data.settlement_institutions).each(function(index, item){
      html += "<div class='col-md-5'>";
      if ($.inArray(item.id,ids)>=0) {
        html += "<input type='checkbox'  value='"+item.id+"' class='form-control' checked='checked' name='user[settlement_institution_ids][]' />";
      }else{
        html += "<input type='checkbox'  value='"+item.id+"' class='form-control' name='user[settlement_institution_ids][]' />";
      };
      html += "<label >"+item.name+"</label>"
      html += "</div>"  
    });
    $(data.other_settlement_institutions).each(function(index, id){
      $("#settlement_hiddens_div").append("<input type='hidden'  name='user[settlement_institution_ids][]' value='"+id+"'>")
    });
    $(control).append(html);
    $(control).change();
    $("[name='user[settlement_institution_ids][]']").each(function(){
      $(this).uniform();
    });
  });
}

function loadAaVendor(name_control, id_control){
  $(name_control).select2({
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
            list.push({ id: item.id, text: item.name });
          });
          return {
            results: list
          }
        }
      },
      initSelection: function (element, callback){
        var data = { id: $(id_control).val(), text: $(name_control).val() };
        callback(data);
      }
    }).change(function(e){
      $(id_control).val(e.val);
    });
}