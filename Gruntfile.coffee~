module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # CoffeeScript compilation of tests
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # BDD tests on browser
    mocha_phantomjs:
      options:
        output: 'spec/result.xml'
        reporter: 'spec'
      all: ['spec/runner.html']

    # Browser build of NoFlo
    noflo_browser:
      build:
        files:
          'browser/noflo-html.js': ['component.json']

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      noflo:
        files:
          './browser/noflo-html.min.js': ['./browser/noflo-html.js']

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee', 'test/*.coffee']
        options:
          reporter: 'spec'
          timeout: 10000
          require: 'coffee-script/register'

    # Coding standards
    coffeelint:
      components:
        files:
          src: ['components/*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'ignore'
      routes:
        files:
          src: ['routes/*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'ignore'
      root:
        files:
          src: ['*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'ignore'

  # Development helpers
  @loadNpmTasks 'grunt-noflo-manifest'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-coffeelint'

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-noflo-browser'
  @loadNpmTasks 'grunt-contrib-uglify'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-cafe-mocha'
  @loadNpmTasks 'grunt-mocha-phantomjs'

  # Our local tasks
  @registerTask 'build', 'Build NoFlo for the chosen target platform', (target = 'all') =>
    @task.run 'coffee'
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'
      @task.run 'uglify'

  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run 'coffeelint'
    @task.run 'coffee'
    if target is 'all' or target is 'nodejs'
      @task.run 'mochaTest'
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'
      @task.run 'mocha_phantomjs'


  # Our local tasks
  @registerTask 'default', ['test']
