import os
import system
import std/json
var cmd = commandLineParams()
var rootDir = cmd[0]
createDir(rootDir)
createDir(rootDir & "/dependencies")
createDir(rootDir & "/dependencies/local")
createDir(rootDir & "/dependencies/remote")
createDir(rootDir & "/plugin")

var RemoteConfigFile = open(rootDir & "/dependencies/remote/remotes.json",fmReadWrite)
var remote_data = %*{"custom_maven_repos":[""],"remotes":[""]}
RemoteConfigFile.write(remote_data)
RemoteConfigFile.close()

var PluginConfigFile = open(rootDir & "/plugin/config.json",fmReadWrite)
var config_data = %*{"name":""}
PluginConfigFile.write(config_data)
PluginConfigFile.close()
echo "空工程已配置完成！"