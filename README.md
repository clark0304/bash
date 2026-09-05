# Bash Tools

## log.sh

> [!NOTE]
>
> `log.sh` 自定义日志格式小工具
>
> - 时刻
> - 报错码
> - 报错信息
> - 彩色格式

## hello.sh

> [!NOTE]
>
> `hello.sh` hello world
>
> - 环境
>   - 检测 shell 类型
>   - 检测 shell 版本
>   - 检测脚本所依赖的命令
> - 参数
>   - 验证参数
>   - 解析参数
> - -h 帮助信息
> - -v 版本信息

```language-plain
Usage:
  ____STR_SYS_BASH_SOURCE____ [OPTION] [ARGUMENT]...

Description:
  Print "Hello [NAME]!" for each [NAME] provided, capitalizing the first letter.

Options:
  -h, --help            Display this help document and exit.
  -v, -V, --version     Display version information and exit.

Arguments:
  NAME                  Iterate name(s) to greet (up to ____INT_ARG_MAX_CNT____).
                        If omitted, defaults to "World".
                        Empty strings are not allowed.

Examples:
  $ ____STR_SYS_BASH_SOURCE____
  Hello World!

  $ ____STR_SYS_BASH_SOURCE____ alpha
  Hello Alpha!

  $ ____STR_SYS_BASH_SOURCE____ Alpha "bravo charlie" '  delta  '
  Hello Alpha!
  Hello Bravo charlie!
  Hello Delta!
```

## user.sh

> [!NOTE]
>
> `user.sh` 初始化系统用户
>
> - 创建组
> - 创建用户, 强制首次登录修改密码
> - 部署 SSH 公钥
