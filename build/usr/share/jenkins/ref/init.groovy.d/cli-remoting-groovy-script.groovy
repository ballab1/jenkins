import jenkins.model.Jenkins

def instance = Jenkins.instance
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)
instance.save()
