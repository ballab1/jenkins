import groovy.json.* 
import groovy.xml.*
import java.text.*


class Updater {
    final static String STABLE_CHANGELOG = 'https://jenkins.io/changelog-stable/rss.xml'
    final static String UPDATE_CENTER_URL = 'http://mirrors.jenkins-ci.org/updates/update-center.json'
    static String PATH = './'
    static String DOCKERFILE_NAME = PATH+'Dockerfile'
    static String PLUGINS_FILENAME = PATH+'build/usr/share/jenkins/ref/plugins.txt'
    static String BACKUP_DIR = PATH+'PluginUpdator'
    def DOCKER_FROM_PATTERN = ~/^ARG\s+ARG JENKINS_VERSION=${JENKINS_VERSION:-([\.0-9]+)}\s*$/

    def myVersionComparitor = null
    def tm = Calendar.instance.time
    
    def getVersions() {
       if (! myVersionComparitor) {
           myVersionComparitor = new GroovyScriptEngine(BACKUP_DIR).loadScriptByName('VersionComparator.groovy').newInstance()
       }
       return myVersionComparitor
    }
    
    int checkForUpdates(Map pluginList, String currentCore) {
        def jsonText = new URL(UPDATE_CENTER_URL).text
        jsonText = jsonText.substring('updateCenter.post('.length())
        jsonText = jsonText.substring(0, jsonText.length()-3)
        
        int isUpdated = 0
        def slurper = new JsonSlurper()
        def json = slurper.parseText(jsonText)
        json.plugins.each { k,v ->
            if (pluginList.containsKey(k) && pluginList[k] != v.version && versions.compare( currentCore, v.requiredCore ) > 0 ) {
                println k+' updated from '+pluginList[k] + ' to '+ v.version
                pluginList[k] = v.version
                isUpdated++
            }
        }
        println isUpdated+' plugins to be updated'
        return isUpdated
    }
    
    String getDockerfileJenkinsVersion(String fileName) {
        String jenkinsVersion = '2.60.3'
        new File(fileName).readLines().each { line ->
            def m =  (line =~ DOCKER_FROM_PATTERN)
            if (m.matches()) {
                jenkinsVersion = m[0][1]
                println "Dockerfile is currently using Jenkins LTS: ${jenkinsVersion}"
            }
        }
        return jenkinsVersion
    }
    
    String getLatestJenkinsLTSversion() {
        def f = new URL(STABLE_CHANGELOG)
        def fmt = new SimpleDateFormat('EEE, d MMM yyyy HH:mm:ss Z')
        def xmlSlurper = new XmlSlurper()
        def xml = xmlSlurper.parseText(f.text)
        ArrayList items = []
        xml.channel.item.each { it ->
           String tm = it.pubDate
           items += [ title : it.title, update : fmt.parse(tm.trim()).time  ]
        }
        String title = items.sort{ a,b -> b.update <=> a.update }[0].title
        println "Latest version of Jenkins LTS: ${title}"
        return title.split(' ')[1]
    }
    
    Map readPluginList(String filename) {
        File f = new File(filename)
        Map pluginList = [:] 
        f.readLines().each { line ->
            ArrayList details = line.split(':')
            pluginList[details[0]] = details[1]
        }
        return pluginList
    }
    
    void saveBackupFile(File file) {
        if (! file.canRead()) {
            println 'failed to read '+file.name+' ('+b.absolutePath+')'
            System.exit(1)
        }
        SimpleDateFormat fmt = new SimpleDateFormat("yyyyMMdd_HHmmss")
        File b = new File(BACKUP_DIR, fmt.format(tm)+'.'+file.name)
        if (! file.renameTo( b )) {
//            if (! b.canWrite()) {
//                println 'failed to write backup '+b.absolutePath+' of file: ('+file.name+')'
//                System.exit(1)
//            }
            b << file
            RandomAccessFile raf = new RandomAccessFile(file, 'rw')
            try {
                raf.setLength(0)
            }
            finally {
                raf.close()
            }
//            if (! file.delete()) {
//                println 'failed to create backup of '+file.name+' ('+b.absolutePath+')'
//                System.exit(1)
//            }
        }
        println 'creating backup of '+file.name
    }
    
    String setDockerfileJenkinsVersion(String dockerfileName, String latestJenkinsLTSversion) {
        File f = new File(dockerfileName)
        def content = f.text
        saveBackupFile(f)
        f = new File(dockerfileName)
        content.readLines().each { line ->
            def m =  (line =~ DOCKER_FROM_PATTERN)
            f << ( ! m.matches() ? line : 'ARG JENKINS_VERSION=${JENKINS_VERSION:-'+latestJenkinsLTSversion+'}' )+"\n"
        }
        return latestJenkinsLTSversion
    }
    
    void updatePlugins(Map pluginList, String fileName) {
        File f = new File(fileName)
        saveBackupFile(f)
        pluginList.each { k,v ->
            f << k + ':' + v + "\n"
        }
    }
    //////////////////////////////////////////////////////////////////////////////
    

    void main() {    
        String dockerfileJenkinsVersion = getDockerfileJenkinsVersion(DOCKERFILE_NAME)
        String latestJenkinsLTSversion = getLatestJenkinsLTSversion()
        
        if (versions.compare( latestJenkinsLTSversion, dockerfileJenkinsVersion ) > 0 ) {
            println 'Jenkins LTS version updated from ' + dockerfileJenkinsVersion + ' to '+ latestJenkinsLTSversion
            dockerfileJenkinsVersion = setDockerfileJenkinsVersion(DOCKERFILE_NAME, latestJenkinsLTSversion)
        }
        
        Map pluginList = readPluginList(PLUGINS_FILENAME)
        if (checkForUpdates(pluginList, dockerfileJenkinsVersion)) {
            updatePlugins(pluginList, PLUGINS_FILENAME)
        }
    }
}
