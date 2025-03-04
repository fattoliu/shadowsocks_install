#!/usr/bin/env bash

# 帮助信息
show_help() {
    echo "用法: $0 [选项...]"
    echo "选项:"
    echo "  -v, --version     指定shadowsocks版本 (1: Python, 2: R, 3: Go, 4: libev) [必需]"
    echo "  -p, --password    设置shadowsocks密码 [必需]"
    echo "  -P, --port       设置端口号 [必需]"
    echo "  -m, --method     设置加密方式 [必需]"
    echo "  -O, --protocol   设置协议 (仅用于SSR) [当version=2时必需]"
    echo "  -o, --obfs       设置混淆 (仅用于SSR) [当version=2时必需]"
    echo "  -g, --obfs-plugin 是否安装simple-obfs (仅用于SS-libev, y或n) [当version=4时必需]"
    echo "  -G, --obfs-type   simple-obfs类型 (http或tls) [当obfs-plugin=y时必需]"
    echo
    echo "示例:"
    echo "  SS-Python:  $0 -v 1 -p mypass -P 8388 -m aes-256-cfb"
    echo "  SSR:        $0 -v 2 -p mypass -P 8388 -m aes-256-cfb -O origin -o plain"
    echo "  SS-Go:      $0 -v 3 -p mypass -P 8388 -m aes-256-cfb"
    echo "  SS-libev:   $0 -v 4 -p mypass -P 8388 -m aes-256-gcm -g y -G http"
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -P|--port)
            PORT="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -O|--protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        -o|--obfs)
            OBFS="$2"
            shift 2
            ;;
        -g|--obfs-plugin)
            OBFS_PLUGIN="$2"
            shift 2
            ;;
        -G|--obfs-type)
            OBFS_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证必需参数
if [ -z "$VERSION" ] || [ -z "$PASSWORD" ] || [ -z "$PORT" ] || [ -z "$METHOD" ]; then
    echo "错误: 缺少必需参数"
    show_help
    exit 1
fi

# 验证版本参数
if ! [[ "$VERSION" =~ ^[1-4]$ ]]; then
    echo "错误: 版本号必须是1-4之间的数字"
    exit 1
fi

# 验证SSR特定参数
if [ "$VERSION" = "2" ] && ([ -z "$PROTOCOL" ] || [ -z "$OBFS" ]); then
    echo "错误: SSR需要指定protocol和obfs参数"
    exit 1
fi

# 验证SS-libev特定参数
if [ "$VERSION" = "4" ] && [ -z "$OBFS_PLUGIN" ]; then
    echo "错误: SS-libev需要指定是否安装obfs插件"
    exit 1
fi

if [ "$VERSION" = "4" ] && [ "$OBFS_PLUGIN" = "y" ] && [ -z "$OBFS_TYPE" ]; then
    echo "错误: 启用obfs插件时需要指定obfs类型"
    exit 1
fi

# 下载原始脚本
wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/fattoliu/shadowsocks_install/refs/heads/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh

# 创建自动回答文件
cat > answers << EOF
${VERSION}
${PASSWORD}
${PORT}
1
EOF

# 根据不同版本添加额外的回答
if [ "$VERSION" = "2" ]; then
    # SSR需要额外的protocol和obfs选项
    echo "1" >> answers  # protocol默认选择第一个
    echo "1" >> answers  # obfs默认选择第一个
elif [ "$VERSION" = "4" ] && [ "$OBFS_PLUGIN" = "y" ]; then
    # SS-libev的obfs配置
    echo "y" >> answers
    if [ "$OBFS_TYPE" = "http" ]; then
        echo "1" >> answers
    else
        echo "2" >> answers
    fi
fi

# 执行安装脚本，使用answers文件自动回答问题
cat answers | ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log

# 清理临时文件
rm -f answers 