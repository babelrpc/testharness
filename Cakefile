fs = require 'fs'
rmdir = require 'rimraf'
mkdirp = require 'mkdirp'
glob = require 'glob'
wrench = require('wrench')
{spawn, exec} = require 'child_process'

task 'dist', 'Build testharness', ->
  console.log "Build testharness in ./babel"  
  if fs.existsSync('build/babel')
    console.log "Cleaning up babel build dir..."
    rmdir.sync 'build/babel', (err)->
      throw err if err 
  console.log "Creating babel build dir..."
  mkdirp.sync 'build', (err)->
    throw err if err
  wrench.copyDirSyncRecursive "src/main/html", "build/babel", {filter:".svn"}, (err) ->
    throw err if err
  wrench.copyDirSyncRecursive "lib", "build/babel/lib", {filter:".svn"}, (err) ->
    throw err if err  
  console.log '   : Compiling templates...'
  exec "handlebars src/main/template/*.handlebars -f build/babel/_templates.js", (err, stdout, stderr) ->
    throw err if err     
    console.log '   : Compiling coffee...' 
    cfiles = glob.sync "**/*.coffee", {}
    exec "coffee --join _babel-ui.js --output build/babel --compile " + cfiles.join(" "), (err, stdout, stderr) ->      
      throw err if err
      console.log '   : Minifying JS...'
      js_files = glob.sync "build/babel/*_*.js"      
      cmd = "uglifyjs " + js_files.join(" ") + " -o build/babel/babel-ui.min.js"
      exec cmd, (err, stdout, stderr) ->
        throw err if err
        for file, index in glob.sync "build/babel/*_*.js"
          fs.unlinkSync file
