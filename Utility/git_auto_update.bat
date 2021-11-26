@echo off

::进入本地库目录
D:
cd workspace\person\local_repositoies

echo start %cd%

::遍历同级目录 非仓库目录也会遍历
for /f %%i in ('"dir /ad/b/on %cd%"') do (
echo %%i
::进入文件夹
cd %%i
git pull
cd ..
echo %%i end
echo.
)
pause