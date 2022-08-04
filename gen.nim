import os
import std/json
import std/sequtils
import std/parsecfg
import std/strutils
import system
import system/io

#是否启用详细输出
var verbose_enabled = false
var localDependencies:seq[string]
const pluginDir = "/plugin"
const localDepDir = "/dependencies/local"
const remoteDepDir = "/dependencies/remote"
const outPutDir = "/output"

#插件的文件名字 xxx.aar
proc get_plugin(path:string):string = 
  var json_path = path & pluginDir & "/config.json"
  var ConfigFile = open(json_path,fmRead)
  var json_node = parseJson(ConfigFile.readAll()) 
  ConfigFile.close()
  var plugin = json_node["name"].getStr()
  if verbose_enabled:
    echo("正在获取config.json数据！")
    echo(json_node)
  echo "任务：get_plugin：获取插件文件名称->完成"
  return plugin

#获得remotes.json里的所有内容
proc getRemotesJson(path:string):JsonNode = 
  var p = path & remoteDepDir & "/remotes.json"
  var File = open(p,fmRead)
  var json_node = parseJson(File.readAll())
  File.close()
  if verbose_enabled:
    echo "正在获取remotes.json数据！"
    echo json_node
  echo "任务：getRemotesJson：获取remotes.json数据->完成"
  return json_node

#把aar插件本体复制过去
proc copyLocalPlugin(path:string, plugin_name:string) = 
  var src = path & pluginDir & "/" & plugin_name
  var dst = path & outPutDir & "/" & plugin_name
  copyFile(src,dst)
  echo "任务：copyLocalPlugin：复制本地插件aar->完成"

proc copyLocalDep(path:string) =
  var p = path & localDepDir
  var targetDir = path & outPutDir
  var files = toSeq(walkFiles(p & "/*.aar"))
  for file in files:
    var file_name = extractFilename(file)
    var target_file = targetDir & "/" & file_name
    localDependencies.add(file_name)
    if verbose_enabled:
      echo "复制文件:" & file & "->" & target_file
    copyFile(file,target_file)
    echo "任务：copyLocalDep：复制本地依赖aar->完成"

proc writePluginConfig(path:string,plugin_name:string,remotes:JsonNode) = 
  var gdap = path & outPutDir & "/build.ini"
  var GdapFile = open(gdap,fmReadWrite)
  var dict = newConfig()
  var name = plugin_name.split(".aar")[0]
  #将序列数组转换为字符串
  var mavens = $remotes["custom_maven_repos"].getElems()
  var remote_libs = $remotes["remotes"].getElems()
  var local_deps = $localDependencies
  #这两个字符串变量需要进一步处理 去掉引号
  mavens = mavens.split("@")[1]
  remote_libs = remote_libs.split("@")[1]
  local_deps = local_deps.split("@")[1]
  dict.setSectionKey("config","name",name)
  dict.setSectionKey("config","binary_type","local")
  dict.setSectionKey("config","binary",plugin_name)
  dict.setSectionKey("config","","")
  dict.setSectionKey("dependencies","custom_maven_repos",mavens)
  dict.setSectionKey("dependencies","local",local_deps)
  dict.setSectionKey("dependencies","remote",remote_libs)
  if verbose_enabled:
    echo "正在对配置文件进行预构建操作！"
    echo dict
  GdapFile.write(dict)
  GdapFile.close()
  echo "任务：weitrPluginConfig：预构建配置文件->完成"

#修一下gdap文件
proc fix_gdap(path:string, plugin_name:string) =
  var str = "" 
  var wrong_gdap = path & outPutDir & "/build.ini"
  #echo wrong_gdap
  for line in lines(wrong_gdap):
    #echo line
    var value = line.split("=")
    if len(value) == 2:
      var t = value[1].strip(leading = true,trailing = true,chars={'\"'})
      var tmp = value[0] & "=" & t
      str &= tmp & "\n"
    else:
      str &= line & "\n"
  if verbose_enabled:
    echo "正在修复gdap字符串数据！"
    echo str
  var gdap = path & outPutDir & "/build.gdap"
  writefile(gdap,str)
  echo "任务：fix_gdap：修复gdap配置文件->完成"

#清除错误的gdap配置文件
proc clean_up(path:string) = 
  remove_file(path & outPutDir & "/build.ini")
  echo "任务：clean_up：清理错误配置文件完成"

proc genGdap(path:string) = 
  var output = path & "/output"
  createDir(output)
  var plugin_name = get_plugin(path)
  var remotes:JsonNode = getRemotesJson(path)
  copyLocalPlugin(path,plugin_name)
  copyLocalDep(path)
  writePluginConfig(path,plugin_name,remotes)
  fix_gdap(path,plugin_name)
  clean_up(path)

#程序入口
var cmd = commandLineParams()
var project_path = cmd[0]
if len(cmd) == 2:
  if cmd[1] == "-v" or cmd[1] == "--verbose":
    verbose_enabled = true
  else:
    echo "错误！不支持的参数！"
genGdap(project_path)