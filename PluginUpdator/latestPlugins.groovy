
def updater = new GroovyScriptEngine('.').loadScriptByName('updater.groovy').newInstance() 
new updater.main()
''