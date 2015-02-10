jQuery(document).ready(function(){

  $('#table_accounting tbody tr .checkboxes').change(function(){

    var once_price = $(this).parents('tr').find("input[id=once_price_" + $(this).val() + "]");
    var fee = $(this).parents('tr').find("input[id=fee_" + $(this).val() + "]");

    var checked = $(this).is(":checked");

    if(checked){
      $(fee).val($(once_price).val());
      $(fee).attr("readonly","");
    }
    else
    {
      $(fee).val('');
      $(fee).removeAttr("readonly")
    }
  });

  $('#create_btn').click(function(){
    change_form();
  });
});

function change_form(){
  var is_change = false;
  $("#table_accounting > tbody > tr").each(function(){
    var checkbox = $(this).find("input[type='checkbox']");

    if($("#fee_" + checkbox.val() + "").val() != "" ){
      is_change = true;
      $("#fee_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][fee]");
      $("#accounting_price_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][caa_fee]")
      $("#addition_fee_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][addition_fee]");
      $("#distance_arrive_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][distance_arrive]");
      $("#distance_drag_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][distance_drag]");
      $("#distance_back_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][distance_back]");
      $("#distance_empty_run_" + checkbox.val() + "").attr("name","accountings[" + checkbox.val() + "][distance_empty_run]");
    }

  });
  
  if(is_change){
    $("#form_accounting").attr("method", "post");
    $("#form_accounting").attr("action", "aa_cases/batch_accounting");
    $("#authenticity_token").attr("name", "authenticity_token");
  }
  
}