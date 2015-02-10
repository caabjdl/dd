jQuery(document).ready(function() {

  $("#aa_case_from_province").change(function(e){
    fillCities($("#aa_case_from_province"), $("#aa_case_from_city"));
  });

  $("#aa_case_from_city").change(function(e){
    fillRegions($("#aa_case_from_province"), $("#aa_case_from_city"), $("#aa_case_from_region"));
  });

  $("#aa_case_to_province").change(function(e){
    fillCities($("#aa_case_to_province"), $("#aa_case_to_city"));
  });

  $("#aa_case_to_city").change(function(e){
    fillRegions($("#aa_case_to_province"), $("#aa_case_to_city"), $("#aa_case_to_region"));
  });

  $("#show_from").click(function(e){
    address = "";
    $.each(['province','city','region','details'],function(i,item){
      address += $('#aa_case_from_' + item).val();
    }); 
    window.showModalDialog ('/aa_cases/map',address,'help:no;scroll:no;resizable:no;status:0;dialogWidth:900px;dialogHeight:600px;center:yes') 
  });

  $("#show_to").click(function(e){
    address = "";
    $.each(['province','city','region','details'],function(i,item){
      address += $('#aa_case_to_' + item).val();
    }); 
    window.showModalDialog ('/aa_cases/map',address,'help:no;scroll:no;resizable:no;status:0;dialogWidth:900px;dialogHeight:600px;center:yes') 
  });
});

