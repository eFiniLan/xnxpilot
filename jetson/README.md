# jetson环境配置
按照顺序执行
0.sh~~~4.sh
注意过程中是否有报错中断，所有报错中断都得处理完才能继续下一步


根目录下的SConstruct，修改如下
```
qt_env.Tool('qt') --->qt_env.Tool('qt3')
```