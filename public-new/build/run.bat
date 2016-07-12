@pushd %~dp0

@set arg=%1
@set orig=%arg:devserver:integration=devserver%

if %arg% == %orig% (
   java -cp "ant\ant.jar;ant\ant-launcher.jar" org.apache.tools.ant.launch.Launcher %*
) else (
   shift
   java -cp "ant\ant.jar;ant\ant-launcher.jar" org.apache.tools.ant.launch.Launcher %orig% %*
)

@popd
