jQuery(document).ready(function() {
if (localStorage && $('form').data('new')==true) 
{
  $('input,textarea').blur(function(){ 
    localStorage.setItem($(this).attr('id'),$(this).val());
  });

  $('.select2me').change(function(){
    localStorage.setItem($(this).attr('id'),$(this).val());
  });

  $('input,textarea').each(function(index,element){
    var value = localStorage.getItem($(this).attr('id'));

    if (value != "undefined" && value != null) {
      $(this).val(value);
    };
  });

  $('.select2me').each(function(index,element){
    var value = localStorage.getItem($(this).attr('id'));

    if (value != "undefined" && value != null) {
      $(this)[0].value = value
    };
  });

  $('form').on("submit", function(e){
    localStorage.clear();
  })
}
});