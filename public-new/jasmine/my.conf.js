// Karma configuration

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '../',


    // plugins: [ require('karma-quixote') ],

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['jasmine', 'quixote'],


    // list of files / patterns to load in the browser
    files: [
      'vendor/assets/javascripts/lodash/lodash.js',
      'vendor/assets/javascripts/lodash-inflection/lodash-inflection.js',
      'app/assets/javascripts/lodash.aspace.js',
      'vendor/assets/javascripts/jquery/jquery.js',
      'vendor/assets/javascripts/exoskeleton/exoskeleton.js',
      'vendor/assets/javascripts/backbone.paginator/backbone.paginator.js',

      'vendor/assets/javascripts/foundation-sites/foundation.core.js',
      'vendor/assets/javascripts/foundation-sites/foundation.util.keyboard.js',
      'vendor/assets/javascripts/foundation-sites/foundation.util.box.js',
      'vendor/assets/javascripts/foundation-sites/foundation.util.triggers.js',
      'vendor/assets/javascripts/foundation-sites/foundation.util.mediaQuery.js',
      'vendor/assets/javascripts/foundation-sites/foundation.util.motion.js',

      'vendor/assets/javascripts/foundation-sites/foundation.reveal.js',
      'vendor/assets/javascripts/foundation-sites/foundation.dropdown.js',
      'vendor/assets/javascripts/foundation-sites/foundation.accordion.js',
      'app/assets/javascripts/record-presenter.js',
      'app/assets/javascripts/*.js',
      'node_modules/jasmine-jquery/lib/jasmine-jquery.js',
      'node_modules/jasmine-ajax/lib/mock-ajax.js',
      'node_modules/jasmine-fixture/dist/jasmine-fixture.js',
      'jasmine/spec_helper.js',
      'jasmine/*.js',
      {
        pattern: 'jasmine/fixtures/*.html',
        watched: false,
        included: false,
        served: true
      },
      {
        pattern: 'app/assets/stylesheets/application.scss',
        watched: false,
        included: false,
        served: true
      }
    ],


    // list of files to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'app/assets/stylesheets/application.scss': ['scss']
    },

    scssPreprocessor: {
      options: {
        sourceMap: true,
        includePaths: ['app/assets/stylesheets', 'vendor/assets/stylesheets']
      }
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Firefox'],
    // browsers: ['Chrome'],
    // browsers: ['PhantomJS2'],

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false
  })
}
