AS = {}

AS.app_prefix = function(path) {
    return APP_PATH + path.replace(/^\//, '');
};