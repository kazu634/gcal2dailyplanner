$('#more > a').on('click', function(e) {
  e.preventDefault();

  $('#description').hide;

  $.ajax({
    url: '/description',
    type: 'POST',
    dataType: 'html',

    success: function( response ) {
      $('#description').html($(response));
    },

    error: function( response ) {
      $('#description').html('<p>データ取得に失敗しました。</p>');
    },

    complete: function( response ) {
      $('#more').hide();
      $('#description').show('slow');
    }
  });
});

$('#login').on('click', function(e) {
  e.preventDefault();
  location.href = "/auth/google_oauth2";
});
