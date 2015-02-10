var Form = function () {

  var handleWysihtml5 = function () {
    if (!jQuery().wysihtml5) {
      return;
    }

    if ($('.wysihtml5').size() > 0) {
      $('.wysihtml5').wysihtml5({
        "stylesheets": ["./assets/plugins/bootstrap-wysihtml5/wysiwyg-color.css"]
      });
    }
  }

  var handleDatePickers = function () {

    if (jQuery().datepicker) {
      $('.date-picker').datepicker({
        rtl: App.isRTL(),
        format: "yyyy-mm-dd",
        autoclose: true,
        
      });
      $('body').removeClass("modal-open"); // fix bug when inline picker is used in modal
    }
  }

  var handleTimePickers = function () {

    if (jQuery().timepicker) {
      $('.timepicker-default').timepicker({
        autoclose: true
      });
      $('.timepicker-24').timepicker({
        autoclose: true,
        minuteStep: 1,
        showSeconds: true,
        showMeridian: false
      });
    }
  }

  var handleDatetimePicker = function () {

    $(".form_datetime").datetimepicker({
      autoclose: true,
      isRTL: App.isRTL(),
      format: "yyyy-mm-dd hh:ii:00",
      pickerPosition: (App.isRTL() ? "bottom-right" : "bottom-left"),
      minuteStep: 1,
      todayBtn: true,
      language: "zh-CN"
    });


    $(".form_advance_datetime").datetimepicker({
      isRTL: App.isRTL(),
      format: "yyyy-mm-dd hh:ii:00",
      autoclose: true,
      todayBtn: true,
      startDate: "2013-02-14 10:00",
      pickerPosition: (App.isRTL() ? "bottom-right" : "bottom-left"),
      minuteStep: 10
    });

    $(".form_meridian_datetime").datetimepicker({
      isRTL: App.isRTL(),
      format: "yyyy-mm-dd HH:ii P",
      showMeridian: true,
      autoclose: true,
      pickerPosition: (App.isRTL() ? "bottom-right" : "bottom-left"),
      todayBtn: true
    });

    $('body').removeClass("modal-open"); // fix bug when inline picker is used in modal
  }

  var handleStickyActionButtons = function(){
    if ($(".form-actions").length != 0){
      offset_init = $(window).height() - $(".footer").outerHeight() - $(".form-actions").outerHeight() - $(".form-actions").offset().top;
      $(".form-actions").css("z-index", 10000)
                        .css("position", "relative")
                        .css("top", $(window).scrollTop() + offset_init);

      //$(window).die("scroll");
      $(window).scroll(function(){
        $(".form-actions").css("top", $(window).scrollTop() + offset_init);
      });

      //$(window).die("resize");
      $(window).resize(function(){
        $(".form-actions").css("position", "static");
        offset_init = $(window).height() - $(".footer").outerHeight() - $(".form-actions").outerHeight() - $(".form-actions").offset().top;

        $(".form-actions").css("position", "relative")
                          .css("top", $(window).scrollTop() + offset_init);
      });
    }
  }

  return {
    //main function to initiate the module
    init: function () {
      handleWysihtml5();
      handleDatePickers();
      handleTimePickers();
      handleDatetimePicker();
      handleStickyActionButtons();
    }
  };

}();