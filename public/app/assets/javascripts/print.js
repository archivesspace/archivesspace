$(function () {
    /* The PDF controller sets a cookie containing a `token` nonce when the
       download starts.  Poll until we see it. */
    var whenDownloadBegins = function(token, callback) {
        var attempt = 0;
        var max_attempts = 60;
        var delay = 1000;

        var next = function () {
            if (document.cookie.indexOf("pdf_generated_" + token) >= 0 || attempt >= max_attempts) {
                callback();
            } else {
                setTimeout(next, delay);
            }
        }

        setTimeout(next, delay);
    };

    $('#print_button').on('click', function (e) {
        var self = $(this);

        var form = self.closest('form');
        var base_token = form.find("input[name='base_token']").attr('value');

        var token = (base_token + new Date().getTime());
        form.find("input[name='token']").attr('value', token);

        self.find('.print-label').hide();
        self.find('.generating-label').show();
        self.attr('disabled', 'disabled');

        whenDownloadBegins(token, function () {
            self.find('.print-label').show();
            self.find('.generating-label').hide();
            self.attr('disabled', null);
        });

        setTimeout(function () {
            form.submit();
        }, 0);

        return false;
    });
});
