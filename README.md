# gdap-generater-nim
gdap配置文件生成器的nim语言移植版

# 使用说明
请打开命令行
1. 创建工程模板 \
init.exe projectName
2. 将文件放进去（参考example文件夹）\
gen.exe projectName \
可选参数 -v 或者--verbose (用于输出详细信息)
# 从源码构建
## linux用户请从源码构建
```
nim c -d:release init.nim
nim c -d:release gen.nim
```
## 32位请从源码构建
```
nim c -d:release init.nim
nim c -d:release gen.nim
```