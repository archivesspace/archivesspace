$(function () {
    var username_typeahead = AS.delayedTypeAhead(function (query, callback) {
        $.ajax({
            url: APP_PATH + "users/complete",
            data: {query: query},
            type: "GET",
            success: function(usernames) {
                callback(usernames);
            },
            error: function() {
                callback([]);
            }
        });
    });

    $("#select-user").typeahead({
        source: username_typeahead.handle
    });
});
