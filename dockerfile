# 使用 Elixir 1.12.3 的官方镜像作为基础
FROM elixir:1.12.3

# 设置工作目录
WORKDIR /app

RUN apt-get update && apt-get install -y curl && \
    curl -I https://repo.hex.pm
# 复制 mix 和 mix.lock 文件
COPY mix.exs mix.lock ./

# 安装 Hex 包管理器和依赖

RUN mix deps.get

# 复制应用源代码
COPY . .

# 编译 Elixir 应用程序
RUN mix compile

# 根据需求，设置环境变量
# ENV MIX_ENV=prod


# 设置默认命令
CMD ["mix", "run", "--no-halt"]

