pushd %~dp0

java -cp "ant\ant.jar;ant\ant-launcher.jar" org.apache.tools.ant.launch.Launcher %*

popd