import org.junit.Test

import static groovy.test.GroovyAssert.shouldFail

class JUnit4ExampleTests {

    def updater = new GroovyScriptEngine('./PluginUpdator').loadScriptByName('updater.groovy').newInstance() 

    @Test
    void testVersion() {
        updater.PATH = './'
        def version = updater.getDockerfileJenkinsVersion('./test/Dockerfile-01')
        assert version == '2.89.2'
    }
    
    @Test
    void testVersionLessThan() {
//        print 'testVersionLessThan:  '
        updater.PATH = './'
        assert updater.versions.compare('2.89.2', '3.89.2') < 0
        assert updater.versions.compare('2.89.2', '2.90.2') < 0
        assert updater.versions.compare('2.89.2', '2.89.3') < 0
        assert updater.versions.compare('2.89.2', '3.90.3') < 0
    }
    
    @Test
    void testVersionGreaterThan() {
//        print 'testVersionGreaterThan:  '
        updater.PATH = './'
        assert updater.versions.compare('1.89.2', '2.89.2') < 0
        assert updater.versions.compare('2.88.2', '2.89.2') < 0
        assert updater.versions.compare('2.89.1', '2.89.2') < 0
        assert updater.versions.compare('1.88.1', '2.89.2') < 0
    }
    
    @Test
    void testVersionSameAs() {
//        print 'testVersionSameAs:  '
        updater.PATH = './'
        assert updater.versions.compare('2.89.2', '2.89.2') == 0
    }
    
    @Test
    void testLatestLTSversion() {
//        print 'testLatestLTSversion:  '
        updater.PATH = './'
        String lts = updater.getLatestJenkinsLTSversion()
        assert lts != null
        assert updater.versions.compare(lts, '2.89.1') > 0
    }
    
    @Test
    void testReadPluginList() {
//        print 'testReadPluginList:  '
        updater.PATH = './'
        Map map = updater.readPluginList('./test/plugins.txt')
        assert map != null
        assert map.size() == 94
    }
    
    @Test
    void testCheckForUpdates() {
//        print 'testCheckForUpdates:  '
        updater.PATH = '../'
        Map map = updater.readPluginList('./test/plugins.txt')
        int st = updater.checkForUpdates(map, '2.89.2')
        assert st == 35
    }
    
    @Test
    void testSetDockerfileJenkinsVersion() {
//        print 'testSetDockerfileJenkinsVersion:  '
        updater.PATH = './'
        def src = new File('./test/Dockerfile-01')
        def dst = new File('./test/Dockerfile-02.txt')
        dst << src.text
        dst = src = null
        assert updater.setDockerfileJenkinsVersion('./test/Dockerfile-02.txt', '2.89.3') == '2.89.3'
    }
    
    @Test
    void testSaveBackupFile() {
//        print 'testSaveBackupFile:  '
        updater.PATH = './'
        def src = new File('./test/Dockerfile-01')
        def dst = new File('./test/Dockerfile-03.txt')
        dst << src.text
        dst = src = null
        int st = 1
        assert st > 0
    }
    
    @Test
    void testUpdatePlugins() {
//        print 'testUpdatePlugins:  '
        updater.PATH = './'
        def src = new File('./test/plugins.txt')
        def dst = new File('./test/plugins-01.txt')
        dst << src.text
        Map map = updater.readPluginList('./test/plugins-01.txt')
        int st = updater.checkForUpdates(map, '2.89.2')
        updater.updatePlugins(map, './test/plugins-01.txt')
        assert st == 35
    }
}
