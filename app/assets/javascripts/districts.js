jQuery(document).ready(function(){

  $("#district_province").change(function(e){
    fillCities($("#district_province"), $("#district_city"));
  });

 



  $("#table_districts .group-checkable").change(function(){
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

  $('#table_districts tbody tr .checkboxes').change(function(){
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
  $("#form_districts").attr("method", "post");
  $("#form_districts").attr("action", "/districts/set_auto_assign");
  $("#authenticity_token").attr("name", "authenticity_token");
  $("#ids").attr("name", "ids").val("");
  var set = $("#table_districts .group-checkable").attr("data-set");
  $(set).each(function(){
    if ($(this).is(":checked")) {
      $("#ids").val($(this).val() + "," + $("#ids").val());
    }
  });
}