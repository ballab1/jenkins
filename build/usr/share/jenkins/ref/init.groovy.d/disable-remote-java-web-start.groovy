// Source: https://support.cloudbees.com/hc/en-us/articles/234709648-Disable-Jenkins-CLI

import jenkins.*
import jenkins.model.*
import hudson.model.*

def protos = AgentProtocol.all()
protos.each { proto ->
    // All remote CLI agent connections are deprecated!
    if (proto.name?.contains("CLI")) {
        protos.remove(proto)
    }
    // while most JNLP is deprecated, currently JNLP4 is still active for Windows agents
    else if ( proto.name?.contains("JNLP") && ! proto.name?.contains("JNLP4") ) {
        protos.remove(proto)
    }
}
instance.save()
