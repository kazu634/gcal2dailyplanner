$(document).on('click', ".pagination > li > a", function(e) {
  e.preventDefault();

  var tmp = $(this).attr("href").split("?");
  var url = tmp[0];

  tmp = tmp[1].split("=");
  var page = tmp[1];

  $.ajax({
    url: url,
    type: 'POST',
    data: {
      page: page,
    },
    dataType: 'html',

    success: function( response ) {
      $('#event-contents').html($(response));
    },

    error: function( response ) {
      $('#event-contents').html('<p>カレンダー情報取得に失敗しました。</p>');
    },

    complete: function( response ) {
      // ...
    }
  });
});

$(document).on('click', "#retrieve, #update", function(e) {
  e.preventDefault();

  $('#event-contents').html('<div class="alert alert-info"><p>GoogleCalendarから予定を取得中です。</p></div>')

  $.ajax({
    url: "/update",
    type: 'POST',
    dataType: 'html',

    success: function( response ) {
      $('#event-contents').html($(response));
    },

    error: function( response ) {
      $('#event-contents').html('<p>カレンダー情報取得に失敗しました。</p>');
    },

    complete: function( response ) {
      location.href = "/mypage"
    }
  });
});

$('document').ready( function () {
  $.ajax({
    url: '/events',
    type: 'POST',
    dataType: 'html',

    success: function( response ) {
      $('#event-contents').html($(response));
    },

    error: function( response ) {
      $('#event-contents').html('<p>カレンダー情報取得に失敗しました</p>');
    },

    complete: function( response ) {
      // ...
    }
  });

})

$('#logoff').on('click', function(e) {
  e.preventDefault();
  location.href = "/logoff";
});
