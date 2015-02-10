jQuery(document).ready(function(){
  $('#unagree').click(function(){
    $("#form").attr("action", "/accounting_jobs/"+$(this).data("id")+"/unagree");
    $("#form").attr("method", "post");
    $("#authenticity_token").attr("name", "authenticity_token");
    $("#form").submit();
    return false;
  });

  $("#table_accounting .group-checkable").change(function(){
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

  $('#table_accounting tbody tr .checkboxes').change(function(){
    $(this).parents('tr').toggleClass("active");
  });

  $('#create_btn').click(function(){
    change_form();
  });

});

function change_form(){
  $("#form").attr("method", "post");
  $("#form").attr("action", "/accounting_jobs/batch_agree");
  $("#authenticity_token").attr("name", "authenticity_token");
  $("#ids").attr("name", "ids").val("");
  var set = $("#table_accounting .group-checkable").attr("data-set");
  $(set).each(function(){
    if ($(this).is(":checked")) {
      $("#ids").val($(this).val() + "," + $("#ids").val());
    }
  });
}

function cul_total(aid)
{
  var arrive = !isNaN(parseFloat($("#confirm_distance_arrive_"+aid).val())) ? parseFloat($("#confirm_distance_arrive_"+aid).val()) : 0;
  var drag = !isNaN(parseFloat($("#confirm_distance_drag_"+aid).val())) ? parseFloat($("#confirm_distance_drag_"+aid).val()) : 0;
  var back = !isNaN(parseFloat($("#confirm_distance_back_"+aid).val())) ? parseFloat($("#confirm_distance_back_"+aid).val()) : 0;
  var empty_run = !isNaN(parseFloat($("#accounting_job_distance_empty_run").val())) ? parseFloat($("#accounting_job_distance_empty_run").val()) : 0;

  $("#total_"+aid).html(arrive+drag+back);

  $.ajax({
      url: "/ajax/aa_vendors/cul_fee?id=" + aid+"&arrive="+ arrive +"&drag="+ drag +"&back="+ back +"&empty_run="+ empty_run 
  }).done(function(data){
    $("#confirm_caa_fee_"+aid).val(data);
    $("#confirm_caa_fee_"+aid).change();
  });
}

function cul_fee(aid)
{
  var addition_fee = !isNaN(parseFloat($("#confirm_addition_fee_"+aid).val())) ? parseFloat($("#confirm_addition_fee_"+aid).val()) : 0;
  var caa_fee = !isNaN(parseFloat($("#confirm_caa_fee_"+aid).val())) ? parseFloat($("#confirm_caa_fee_"+aid).val()) : 0;
  $("#confirm_fee_"+aid).val(addition_fee+caa_fee);
}
