import groovy.json.* 
import groovy.xml.*
import java.text.*


class Updator {
    def PATH = './'
    def DOCKERFILE_NAME = PATH+'Dockerfile'
    def STABLE_CHANGELOG = 'https://jenkins.io/changelog-stable/rss.xml'
    def PLUGINS_FILENAME = PATH+'build/usr/share/jenkins/ref/plugins.txt'
    def UPDATE_CENTER_URL = 'http://mirrors.jenkins-ci.org/updates/update-center.json'
    def BACKUP_DIR = PATH+'PluginUpdator'
    def DOCKER_FROM_PATTERN = ~/^FROM\s+.*:([.0-9]+)-alpine/

    def VersionComparator = new GroovyScriptEngine(BACKUP_DIR).loadScriptByName('VersionComparator.groovy').newInstance()
    def tm = Calendar.instance.time
    
    def checkForUpdates(url, pluginList, currentCore) {
        def jsonText = new URL(url).text
        jsonText = jsonText.substring('updateCenter.post('.length())
        jsonText = jsonText.substring(0, jsonText.length()-3)
        
        def isUpdated = 0
        def slurper = new JsonSlurper()
        def json = slurper.parseText(jsonText)
        json.plugins.each { k,v ->
            if (pluginList.containsKey(k) && pluginList[k] != v.version && VersionComparator.compare( currentCore, v.requiredCore ) > 0 ) {
                println k+' updated from '+pluginList[k] + ' to '+ v.version
                pluginList[k] = v.version
                isUpdated++
            }
        }
        println isUpdated+' plugins to be updated'
        return isUpdated
    }
    
    def getDockerfileJenkinsVersion(fileName) {
        def jenkinsVersion = '2.60.3'
        new File(fileName).readLines().each { line ->
            def m =  (line =~ DOCKER_FROM_PATTERN)
            if (m.matches()) {
                jenkinsVersion = m[0][1]
            }
        }
        return jenkinsVersion
    }
    
    def getLatestJenkinsLTSversion(url) {
        def f = new URL(url)
        def fmt = new SimpleDateFormat('EEE, d MMM yyyy HH:mm:ss Z')
        def xmlSlurper = new XmlSlurper()
        def xml = xmlSlurper.parseText(f.text)
        def items = []
        xml.channel.item.each { it ->
           String tm = it.pubDate
           items += [ title : it.title, update : fmt.parse(tm.trim()).time  ]
        }
        String title = items.sort{ a,b -> b.update <=> a.update }[0].title
        return title.split(' ')[1]
    }
    
    def readPluginList(filename) {
        def f = new File(filename)
        def pluginList = [:] 
        f.readLines().each { line ->
            def details = line.split(':')
            pluginList[details[0]] = details[1]
        }
        return pluginList
    }
    
    def saveBackupFile(fileName) {
        def fmt = new SimpleDateFormat("yyyyMMdd_HHmmss")
        def b = new File(BACKUP_DIR, fmt.format(tm)+'.'+fileName.name)
        if (! fileName.renameTo( b )) {
            println 'failed to create backup of '+fileName.name
            System.exit(1)
        }
        println 'creating backup of '+fileName.name
        return b
    }
    
    def setDockerfileJenkinsVersion(dockerfileName, latestJenkinsLTSversion) {
        def f = saveBackupFile(new File(dockerfileName))
        f.readLines().each { line ->
            def m =  (line =~ DOCKER_FROM_PATTERN)
            if (m.matches()) {
                line = 'FROM jenkins/jenkins:'+latestJenkinsLTSversion+'-alpine'
            }
            f << line + "\n"
        }
        return latestJenkinsLTSversion
    }
    
    def updatePlugins(pluginList, fileName) {
        def f = new File(fileName)
        saveBackupFile(f)
        pluginList.each { k,v ->
            f << k + ':' + v + "\n"
        }
    }
    //////////////////////////////////////////////////////////////////////////////
    

    def main() {    
        def dockerfileJenkinsVersion = getDockerfileJenkinsVersion(DOCKERFILE_NAME)
        def latestJenkinsLTSversion = getLatestJenkinsLTSversion(STABLE_CHANGELOG)
        
        if (VersionComparator.compare( latestJenkinsLTSversion, dockerfileJenkinsVersion ) > 0 ) {
            println 'Jenkins LTS version updated from ' + dockerfileJenkinsVersion + ' to '+ latestJenkinsLTSversion
            dockerfileJenkinsVersion = setDockerfileJenkinsVersion(DOCKERFILE_NAME, latestJenkinsLTSversion)
        }
        
        def pluginList = readPluginList(PLUGINS_FILENAME)
        if (checkForUpdates(UPDATE_CENTER_URL, pluginList, dockerfileJenkinsVersion)) {
            updatePlugins(pluginList, PLUGINS_FILENAME)
        }
    }
}

new Updator().main()
'' 
