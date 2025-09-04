//@GrabResolver(name='JSON.simple', root='http://code.google.com/p/json-simple')
//@Grab(group='grails.plugins', module='VersionComparator', version='3.3.0')

import groovy.json.*
import groovy.xml.*
import java.text.*
import java.security.MessageDigest
//import grails.plugins.VersionComparator
//import org.codehaus.groovy.grails.plugins.VersionComparator

class Updater {
    final static String STABLE_CHANGELOG = 'https://www.jenkins.io/changelog-stable/rss.xml'
    final static String UPDATE_CENTER_URL = 'https://updates.jenkins.io/dynamic-stable-'
    final static String LTS_WAR_URL_BASE = 'https://repo.jenkins.io/public/org/jenkins-ci/main/jenkins-war/'
    final static def VERSION_PATTERN_IN_DOCKERFILE = ~/^ARG\s+JENKINS_VERSION=([.0-9]+)\s*$/
    final static def VERSION_PATTERN_IN_DOCKER_COMPOSE = ~/(\s+image:\s+.+jenkins\/\$\{JENKINS_VERSION:-)(.+)(\}:\$\{CONTAINER_TAG.*)$/
    static String PATH = './'
    static String DOCKER_COMPOSE_NAME = PATH + 'data/docker-compose.yml'
    static String CURRENT_VERSIONS = PATH + 'versions/alpine'
    static String DOCKERFILE_NAME = PATH + 'data/Dockerfile'
    static String DOWNLOAD_FILE_NAME = PATH + 'data/build/action_folders/04.downloads/01.JENKINS'
    static String PLUGINS_FILENAME = PATH + 'data/build/usr/share/jenkins/ref/plugins.txt'
    static String BACKUP_DIR = PATH + 'scripts'

    def myVersionComparator = null
    def tm = Calendar.instance.time
    def _latestJenkinsLTSversion = null
    def _latestJenkinsStableVersion = null

    int checkForUpdates(Map pluginList, String currentCore) {
        def jsonText = this.getUpdateCenterJSON()

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

    String formatDownloadsHashLine(String version) {
        String url = LTS_WAR_URL_BASE + version + '/jenkins-war-' + version + '.war'
        String sha256 = sha256sum(url)
        return "JENKINS['sha256_${version}']=\"${sha256}\"\n"
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

    String getLatestStableVersion() {
        if (_latestJenkinsStableVersion == null) {
            def f = new File(this.CURRENT_VERSIONS)
            Map versions = [:]
            f.readLines().each { line ->
                ArrayList details = line.split('=')
                versions[details[0]] = details[1]
            }
            String title = versions['JENKINS_DYNAMIC_STABLE']
            println "Latest version of JenkinsPlugins: ${title}"
            _latestJenkinsStableVersion = title
        }
        return _latestJenkinsStableVersion
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

    String getUpdateCenterJSON() {
        String url = this.UPDATE_CENTER_URL + this.getLatestStableVersion() + '/update-center.actual.json'
        def jsonText = new URL(url).text
        return jsonText
    }

    def getVersions() {
       if (! myVersionComparator) {
           myVersionComparator = new GroovyScriptEngine(this.BACKUP_DIR).loadScriptByName('VersionComparator.groovy').newInstance()
       }
       return myVersionComparator
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
            println 'failed to read '+file.name+' ('+fileName.absolutePath+')'
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

    void setDockerComposeVersion(String version) {
        // update version info in Dockerfile
        def content = saveBackupFile(this.DOCKER_COMPOSE_NAME)
        File f = new File(this.DOCKER_COMPOSE_NAME)
        content.readLines().each { line ->
            def m =  (line =~ this.VERSION_PATTERN_IN_DOCKER_COMPOSE)
            f << ( ! m.matches() ? line : m[0][1] + version + m[0][3] ) + "\n"
        }
    }

    void setDockerFileVersion(String version) {
        // update version info in Dockerfile
        def content = saveBackupFile(this.DOCKERFILE_NAME)
        File f = new File(this.DOCKERFILE_NAME)
        content.readLines().each { line ->
            def m =  (line =~ this.VERSION_PATTERN_IN_DOCKERFILE)
            f << ( ! m.matches() ? line : 'ARG JENKINS_VERSION='+version )+"\n"
        }
    }

    void setDownloadsHash(String version) {
        // update version info in 'build/action_folders/04.downloads/01.JENKINS'
        def content = saveBackupFile(this.DOWNLOAD_FILE_NAME)
        File f = new File(this.DOWNLOAD_FILE_NAME)
        content.readLines().each { line ->
            if ( line =~ /JENKINS\['sha256'\]=/ ) {
                f << formatDownloadsHashLine(version)
            }
            f << line + "\n"
        }
    }

    void setJenkinsVersion(String version) {
        setDockerComposeVersion(version)
        setDockerFileVersion(version)
        setDownloadsHash(version)
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
            return partialHash.encodeHex().toString()
        }
        catch (Exception e) {
            println "Failed to calculate SHA-256.  bytes read: ${total}\n" + e.message
            e.printStackTrace()
//            System.exit(1)
        }
        finally {
            if (data)
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