# 使用 Elixir 1.12.3 的官方镜像作为基础
FROM elixir:1.12.3

# 设置工作目录
WORKDIR /app

# 复制 mix 和 mix.lock 文件
COPY mix.exs mix.lock ./

# 安装 Hex 包管理器和依赖
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

# 复制应用源代码
COPY . .

# 编译 Elixir 应用程序
RUN mix compile

# 根据需求，设置环境变量
# ENV MIX_ENV=prod

# 编译生产环境静态文件（如果使用 Phoenix）
# RUN mix phx.digest

# 设置默认命令
CMD ["mix", "run", "--no-halt"]

