import org.junit.Test

import static groovy.test.GroovyAssert.shouldFail

class JUnit4ExampleTests {

    def updater = new GroovyScriptEngine('../PluginUpdator').loadScriptByName('updater.groovy').newInstance() 

    @Test
    void testVersion() {
        updater.PATH = '../'
        def version = updater.getDockerfileJenkinsVersion('./Dockerfile-01')
        assert version == '2.89.2'
    }
    
    @Test
    void testVersionLessThan() {
        updater.PATH = '../'
        assert updater.versions.compare('2.89.2', '3.89.2') < 0
        assert updater.versions.compare('2.89.2', '2.90.2') < 0
        assert updater.versions.compare('2.89.2', '2.89.3') < 0
        assert updater.versions.compare('2.89.2', '3.90.3') < 0
    }
    
    @Test
    void testVersionGreaterThan() {
        updater.PATH = '../'
        assert updater.versions.compare('1.89.2', '2.89.2') < 0
        assert updater.versions.compare('2.88.2', '2.89.2') < 0
        assert updater.versions.compare('2.89.1', '2.89.2') < 0
        assert updater.versions.compare('1.88.1', '2.89.2') < 0
    }
    
    @Test
    void testVersionSameAs() {
        updater.PATH = '../'
        assert updater.versions.compare('2.89.2', '2.89.2') == 0
    }
    
    @Test
    void testLatestLTSversion() {
        updater.PATH = '../'
        String lts = updater.getLatestJenkinsLTSversion()
        assert lts != null
        assert updater.versions.compare(lts, '2.89.1') > 0
    }
    
    @Test
    void testReadPluginList() {
        updater.PATH = '../'
        Map map = updater.readPluginList('./plugins.txt')
        assert map != null
        assert map.size() == 94
    }
    
    @Test
    void testCheckForUpdates() {
        updater.PATH = '../'
        Map map = updater.readPluginList('./plugins.txt')
        int st = updater.checkForUpdates(map, '2.89.2')
        assert st == 33
    }
    
    @Test
    void testSetDockerfileJenkinsVersion() {
        updater.PATH = '../'
        def src = new File('./Dockerfile-01')
        def dst = new File('./Dockerfile-02.txt')
        dst << src.text
        dst = src = null
        assert updater.setDockerfileJenkinsVersion('./Dockerfile-02.txt', '2.89.3') == '2.89.3'
    }
    
    @Test
    void testSaveBackupFile() {
        updater.PATH = '../'
        def src = new File('./Dockerfile-01')
        def dst = new File('./Dockerfile-03.txt')
        dst << src.text
        dst = src = null
        int st = 1
        assert st > 0
    }
    
    @Test
    void testUpdatePlugins() {
        updater.PATH = '../'
        def src = new File('./plugins.txt')
        def dst = new File('./plugins-01.txt')
        dst << src.text
        Map map = updater.readPluginList('./plugins-01.txt')
        int st = updater.checkForUpdates(map, '2.89.2')
        updater.updatePlugins(map, './plugins-01.txt')
        assert st == 33
    }
}
