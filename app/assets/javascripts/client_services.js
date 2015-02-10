jQuery(document).ready(function(){
  $("#table_client_services .group-checkable").change(function(){
    var set = $(this).attr("data-set");
    var checked = $(this).is(":checked");
    $(set).each(function(){
      if(checked){
        $(this).attr("checked", true);
      }else{
        $(this).attr("checked", false);
      }
      $(this).parents('tr').toggleClass("active");
    });
    $.uniform.update(set);
  });

  $('#table_client_services tbody tr .checkboxes').change(function(){
    $(this).parents('tr').toggleClass("active");
  });

  $('#enable_auto_assign').click(function(){
    change_form();
    $("#type").attr("name", "type").val("enable");
  });

  $('#disable_auto_assign').click(function(){
    change_form();
    $("#type").attr("name", "type").val("disable");
  });
});

function change_form(){
  $("#form_client_services").attr("method", "post");
  $("#form_client_services").attr("action", "client_services/set_auto_assign");
  $("#authenticity_token").attr("name", "authenticity_token");
  $("#ids").attr("name", "ids").val("");
  var set = $("#table_client_services .group-checkable").attr("data-set");
  $(set).each(function(){
    if ($(this).is(":checked")) {
      $("#ids").val($(this).val() + "," + $("#ids").val());
    }
  });
}