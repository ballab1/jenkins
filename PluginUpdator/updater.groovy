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
    final static String STABLE_CHANGELOG = 'https://www.jenkins.io/changelog-stable/rss.xml'
//    final static String UPDATE_CENTER_URL = 'http://mirrors.jenkins-ci.org/updates/update-center.json'
    final static String UPDATE_CENTER_URL = 'https://ftp-nyc.osuosl.org/pub/jenkins/updates/update-center.json'
    final static def VERSION_PATTERN_IN_DOCKERFILE = ~/^ARG\s+JENKINS_VERSION=([.0-9]+)\s*$/
    final static def VERSION_PATTERN_IN_DOCKERCOMPOSE = ~/(\s+image:\s+.+jenkins\/\$\{JENKINS_VERSION:-)(.+)(\}:\$\{CONTAINER_TAG.*)$/
    static String PATH = './'
    static String DOCKERCOMPOSE_NAME = PATH+'docker-compose.yml'
    static String DOCKERFILE_NAME = PATH+'Dockerfile'
    static String DOWNLOAD_FILE_NAME = PATH+'build/action_folders/04.downloads/01.JENKINS'
    static String PLUGINS_FILENAME = PATH+'build/usr/share/jenkins/ref/plugins.txt'
    static String BACKUP_DIR = PATH+'PluginUpdator'

    def myVersionComparitor = null
    def tm = Calendar.instance.time
    def _latestJenkinsLTSversion = null

    def getVersions() {
       if (! myVersionComparitor) {
           myVersionComparitor = new GroovyScriptEngine(this.BACKUP_DIR).loadScriptByName('VersionComparator.groovy').newInstance()
       }
       return myVersionComparitor
    }

    int checkForUpdates(Map pluginList, String currentCore) {
        def jsonText = new URL(this.UPDATE_CENTER_URL).text
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

    String getDockerfileJenkinsVersion() {
        String jenkinsVersion = ''
        new File(this.DOCKERFILE_NAME).readLines().each { line ->
            def m =  (line =~ this.VERSION_PATTERN_IN_DOCKERFILE)
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
            def f = new URL(this.STABLE_CHANGELOG)
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

    def saveBackupFile(String fileName) {
        File file = new File(fileName)
        if (! file.canRead()) {
            println 'failed to read '+file.name+' ('+b.absolutePath+')'
            System.exit(1)
        }
        SimpleDateFormat fmt = new SimpleDateFormat("yyyyMMdd_HHmmss")
        println 'creating backup of '+file.name

        def content = file.text
        File b = new File(this.BACKUP_DIR, fmt.format(tm)+'.'+file.name)
        b << content

        RandomAccessFile raf = new RandomAccessFile(file, 'rw')
        try {
            raf.setLength(0)
        }
        finally {
            raf.close()
        }
        return content
    }

    void setDockerComposeVersion(String latestJenkinsLTSversion) {
        // update version info in Dockerfile
        def content = saveBackupFile(this.DOCKERCOMPOSE_NAME)
        File f = new File(this.DOCKERCOMPOSE_NAME)
        content.readLines().each { line ->
            def m =  (line =~ this.VERSION_PATTERN_IN_DOCKERCOMPOSE)
            f << ( ! m.matches() ? line : m[0][1]+latestJenkinsLTSversion+m[0][3] )+"\n"
        }
    }

    void setDockerFileVersion(String latestJenkinsLTSversion) {
        // update version info in Dockerfile
        def content = saveBackupFile(this.DOCKERFILE_NAME)
        File f = new File(this.DOCKERFILE_NAME)
        content.readLines().each { line ->
            def m =  (line =~ this.VERSION_PATTERN_IN_DOCKERFILE)
            f << ( ! m.matches() ? line : 'ARG JENKINS_VERSION='+latestJenkinsLTSversion )+"\n"
        }
    }

    void setDownloadsHash(String latestJenkinsLTSversion) {
        // update version info in 'build/action_folders/04.downloads/01.JENKINS'
        def content = saveBackupFile(this.DOWNLOAD_FILE_NAME)
        File f = new File(this.DOWNLOAD_FILE_NAME)
        content.readLines().each { line ->
            if ( line =~ /JENKINS\['sha256'\]=/ ) {
                String sha256 = sha256sum("https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${latestJenkinsLTSversion}/jenkins-war-${latestJenkinsLTSversion}.war")
                f << "JENKINS['sha256_${latestJenkinsLTSversion}']=\"${sha256}\"\n"
            }
            f << line + "\n"
        }
    }

    void setJenkinsVersion(String latestJenkinsLTSversion) {
        setDockerComposeVersion(latestJenkinsLTSversion)
        setDockerFileVersion(latestJenkinsLTSversion)
        setDownloadsHash(latestJenkinsLTSversion)
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
        saveBackupFile(fileName)
        File f = new File(fileName)
        pluginList.each { k,v ->
            f << k + ':' + v + "\n"
        }
    }

    //////////////////////////////////////////////////////////////////////////////


    void main() {
        String dockerfileVersion = getDockerfileJenkinsVersion()
        if ( dockerfileVersion.length() == 0 ) {
            println '\nUnable to parse JENKINS_VERSION from Dockerfile'
            System.exit(1)
        }
        String latestLTSversion = getLatestJenkinsLTSversion()

        if (versions.compare( latestLTSversion, dockerfileVersion ) > 0 ) {
            println 'Jenkins LTS version updated from ' + dockerfileVersion + ' to '+ latestLTSversion
            setJenkinsVersion(latestLTSversion)
        }

        Map pluginList = readPluginList(this.PLUGINS_FILENAME)
        if (checkForUpdates(pluginList, latestLTSversion)) {
            updatePlugins(pluginList, this.PLUGINS_FILENAME)
        }
    }
}
