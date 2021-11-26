@echo off

::进入本地库目录 切换磁盘时需要额外增加参数 "/d" 表示切换到新磁盘
cd /d E:\WorkStation\PersonRepositories

echo start auto check local repositories
echo.

::遍历同级目录 非仓库目录也会遍历
for /f %%j in ('"dir /ad/b/on %cd%"') do (
cd %%j

::进入子目录遍历
for /f %%i in ('"dir /ad/b/on %cd%\%%j"') do (
::进入文件夹 执行git status
cd %%i
echo ====================%%j %%i====================
git status
cd ..
echo.
)

cd ..
)
pause