//@GrabResolver(name='JSON.simple', root='http://code.google.com/p/json-simple')
//@Grab(group='grails.plugins', module='VersionComparator', version='3.3.0') 

import groovy.json.* 
import groovy.xml.*
import java.text.*
import java.security.MessageDigest
import javax.xml.bind.DatatypeConverter
//import grails.plugins.VersionComparator
//import org.codehaus.groovy.grails.plugins.VersionComparator

class Updater {
    final static String STABLE_CHANGELOG = 'https://jenkins.io/changelog-stable/rss.xml'
    final static String UPDATE_CENTER_URL = 'http://mirrors.jenkins-ci.org/updates/update-center.json'
    static String PATH = './'
    static String DOCKERFILE_NAME = PATH+'Dockerfile'
    static String DOWNLOAD_FILE_NAME = PATH+'build/action_folders/04.downloads/01.JENKINS'
    static String PLUGINS_FILENAME = PATH+'build/usr/share/jenkins/ref/plugins.txt'
    static String BACKUP_DIR = PATH+'PluginUpdator'
    def VERSION_PATTERN_IN_DOCKERFILE = ~/^ARG\s+JENKINS_VERSION=([.0-9]+)\s*$/

    def myVersionComparitor = null
    def tm = Calendar.instance.time
    def _latestJenkinsLTSversion = null
    
    def getVersions() {
       if (! myVersionComparitor) {
           myVersionComparitor = new GroovyScriptEngine(BACKUP_DIR).loadScriptByName('VersionComparator.groovy').newInstance()
//           myVersionComparitor = new VersionComparator
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
            def m =  (line =~ VERSION_PATTERN_IN_DOCKERFILE)
            if (m.matches()) {
                jenkinsVersion = m[0][1]
                println ''
                println "Dockerfile is currently using Jenkins LTS: ${jenkinsVersion}"
            }
        }
        return jenkinsVersion
    }
    
    String getLatestJenkinsLTSversion() {
        if (_latestJenkinsLTSversion == null) {
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
            _latestJenkinsLTSversion = title.split(' ')[1]
        }
        return _latestJenkinsLTSversion
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
        println 'creating backup of '+file.name

        File b = new File(BACKUP_DIR, fmt.format(tm)+'.'+file.name)
        if (! file.renameTo( b )) {
            println "....unable to rename ${file.name} to ${b.absolutePath}. Copying file." 

            b << file.text
            println "....shrinking original ${file.name}" 
            RandomAccessFile raf = new RandomAccessFile(file, 'rw')
            try {
                raf.setLength(0)
            }
            finally {
                raf.close()
            }
        }
    }
    
    String setJenkinsVersion(String latestJenkinsLTSversion) {
        // update version info in Dockerfile
        File f = new File(DOCKERFILE_NAME)
        def content = f.text
        saveBackupFile(f)
        f = new File(dockerfileName)
        content.readLines().each { line ->
            def m =  (line =~ VERSION_PATTERN_IN_DOCKERFILE)
            f << ( ! m.matches() ? line : 'ARG JENKINS_VERSION='+latestJenkinsLTSversion )+"\n"
        }

        // update version info in 'build/action_folders/04.downloads/01.JENKINS'
        f = new File(DOWNLOAD_FILE_NAME)
        content = f.text
        saveBackupFile(f)
        f = new File(dockerfileName)
        content.readLines().each { line ->
            if ( line =~ /\['version'\]/ ) {
                f << "    ['version']=\${JENKINS_VERSION:-${latestJenkinsLTSversion}}\n"
            }
            else if ( line =~ /\['sha256'\]/ ) {
                String sha256 = sha256sum("https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${latestJenkinsLTSversion}/jenkins-war-${latestJenkinsLTSversion}.war")
                f << "    ['sha256']=\"${sha256}\"\n"
            }
            else {
                f << line
            }
        }

    }
    
    String sha256sum(String url) {
        long total = 0
        InputStream data = null
        try {
            data = new BufferedInputStream(new URL(url).openStream())
            MessageDigest hashSum = MessageDigest.getInstance("SHA-256")

            int bufSize = 4096
            byte[] buffer = new byte[bufSize];
            int bytesRead
            while((bytesRead = data.read(buffer,0,bufSize)) != -1) {
                total += bytesRead
                hashSum.update(buffer, 0, bytesRead)
            }
            byte[] partialHash = null
            partialHash = new byte[hashSum.getDigestLength()]
            partialHash = hashSum.digest()
            return DatatypeConverter.printHexBinary(partialHash).toString().toLowerCase()
        }
        catch (Exception e) {
            println "Failed to calculate SHA-256.  bytes read: ${total}\n" + e.message
            e.printStackTrace()
//            System.exit(1)
        }
        finally {
            data.close()
        }
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
            setJenkinsVersion(latestJenkinsLTSversion)
        }
        
        Map pluginList = readPluginList(PLUGINS_FILENAME)
        if (checkForUpdates(pluginList, dockerfileJenkinsVersion)) {
            updatePlugins(pluginList, PLUGINS_FILENAME)
        }
    }
}
