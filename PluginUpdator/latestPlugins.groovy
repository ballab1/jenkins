
def updater = new GroovyScriptEngine('scripts').loadScriptByName('updater.groovy').newInstance()
updater.main()
