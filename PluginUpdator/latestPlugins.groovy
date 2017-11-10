import groovy.json.*

def VersionComparator = new GroovyScriptEngine('PluginUpdator').loadScriptByName('VersionComparator.groovy').newInstance()
def currentCore = '2.60.3'
def pattern = ~/^FROM\s+.*:([.0-9]+)-alpine/
new File('./Dockerfile').readLines().each { line ->
	def m =  (line =~ pattern)
	if (m.matches()) {
		currentCore = m[0][1]
	}
}
println 'Jenkins version v'+currentCore

def isUpdated = 0

def f = new File('container/plugins.txt')
def pluginList = [:] 
f.readLines().each { line ->
    def details = line.split(':')
    pluginList[details[0]] = details[1]
}

f = new URL('http://mirrors.jenkins-ci.org/updates/update-center.json')
def jsonText = f.text
jsonText = jsonText.substring('updateCenter.post('.length())
jsonText = jsonText.substring(0, jsonText.length()-3)

def slurper = new JsonSlurper()
def json = slurper.parseText(jsonText)
json.plugins.each { k,v ->
    if (pluginList.containsKey(k) && pluginList[k] != v.version && VersionComparator.compare( currentCore, v.requiredCore ) > 0 ) {
        println k+' updated from '+pluginList[k] + ' to '+ v.version
        pluginList[k] = v.version
        isUpdated++
    }
}

if (isUpdated == 0) {
    println 'No plugins updated'
}
else {
    def fmt = new java.text.SimpleDateFormat("yyyyymmdd_hhmmss")
    f = new File('container/plugins.txt')
    f = f.renameTo( new File('PluginUpdator/plugins.' + fmt.format(Calendar.instance.time) + '.txt') )
    f = new File('container/plugins.txt')
    pluginList.each { k,v ->
        f << k + ':' + v + "\n"
    }
    f = null
    println isUpdated+' plugins updated'
}
''
