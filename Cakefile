muffin = require 'muffin'

task 'build', 'compile coffee', (options) ->
  muffin.run
    files: './src/**/*'
    options: options
    map:
      'src/(.+).coffee' : (matches) -> muffin.compileScript(matches[0], "lib/#{matches[1]}.js", options)
