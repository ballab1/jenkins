# Plugin Updator
## Basic jenkins container populated with required plugins for home setup

Requires GROOVY to build & run

Files:
 - latestCore.txt contains       version number of Jenkins
 - latestPlugins.groovy          script to run

run the 'latestPlugins.groovy' script to 
 -  read the current Jenkins core version from [latestCore.txt](latestCore.txt)
 -  download the [update-center.json](http://mirrors.jenkins-ci.org/updates/update-center.json)
 -  parse the file
 -  read the current list of plugins and versions from [../container/plugins.txt](../container/plugins.txt)
 -  compare the list of pluginst agains the latest update-center.json
 -  report what can be updated
 -  produce a new plugins.txt file in the current folder
 
 After running the script, and generating an updated plugin.txt file, commit the file into this repo and rebuild the Docker container 