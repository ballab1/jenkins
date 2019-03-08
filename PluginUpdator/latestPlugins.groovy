
def updater = new GroovyScriptEngine('PluginUpdator').loadScriptByName('updater.groovy').newInstance() 
updater.main()
