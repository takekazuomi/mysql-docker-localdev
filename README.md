# MySQL docker local dev

MySQLを使った開発のdockerサンプル[^mysql]

## mysql ローカルコンテナ

この後、アプリをコードを入れるだろうから、docker compose を使う方針で行く。

[docker-compose.yaml](./docker-compose.yaml)

```yaml
version: '3'

services:
  db:
    image: mysql:8.0.29
    ports:
      - ${MYSQL_PORT:-3306}:3306
    user: ${UID_GID:-1000:1000}
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/initdb.d:/docker-entrypoint-initdb.d
    environment:
      - MYSQL_RANDOM_ROOT_PASSWORD=yes
      - MYSQL_USER=${MYSQL_USER:-dbuser}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-dbpass}
      - MYSQL_DATABASE=${MYSQL_DATABASE:-db}
    restart: always
    networks:
      - backend

networks:
  backend:
    driver: bridge
    name: backend_network
```

### 概略

デフォルトのままの場合コンテナはrootで実行され、bind mount されたホストのファイルシステムに root 権限のファイルが作成される。それだと使いづらいので、コンテナプロセスを実行するユーザーのユーザーID, グループIDを指定して、ホスト側のユーザーと揃える。[^user]

```yaml
user: "${UID_GID:-1000:1000}"
```

MySQLのデータと初期化SQLを保存する、ホストのパスを指定する。[^bind]

```yaml
volumes:
  - ./mysql/data:/var/lib/mysql
  - ./mysql/initdb.d:/docker-entrypoint-initdb.d
```

環境変数で、MySQLの初期設定を行う。[^env] それぞれの値を環境変数で上書きできるように`${MYSQL_USER:-dbuser}`のようにした。[^var]

```yaml
environment:
  - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-mysql}
  - MYSQL_USER=${MYSQL_USER:-dbuser}
  - MYSQL_PASSWORD=${MYSQL_PASSWORD:-dbpass}
  - MYSQL_DATABASE=${MYSQL_DATABASE:-db}
```

### 初期化SQL

`initdb.d/01_server_variable.sql` でMySQLの初期化SQLをながす。ここでは、文字種とTZを設定している。

```sql:initdb.d/01_server_variable.sql
set persist local_infile=on;
set persist character_set_server=utf8mb4;
set persist collation_server=utf8mb4_general_ci;
set persist time_zone='Asia/Tokyo';
```

## 環境変数での上書き

環境変数の設定は、`docker compose` の環境ファイルと、[direnv](https://github.com/direnv/direnv) を組み合わせで行う。

コンテナで必要な設定のうちパスワードなど機密情報ではないものは、`.env` に記載する。`.env` ファイル(デフォルトの環境変数ファイル)は、
`docker compose` で自動的に読み込まれる。[^var]

```text:.env
MYSQL_USER=dbuser
MYSQL_DATABASE=db
```

`.envrc` では、`dotenv` で、`.env` を読み込ませる。[^dotenv] `./.envrc.local` があれば読み込む[^source_env]

```sh:.envrc
dotenv
[[ ! -f ./.envrc.local ]] || source_env ./.envrc.local
```

`./.envrc.local` は、git-ignore[^gitignore] し、シークレットなど、ローカル環境で上書きしたい内容を書く。

```sh:.envrc
export MYSQL_ROOT_PASSWORD=mysql
export MYSQL_PASSWORD=dbpass
```

※ 本環境はローカルでだけ実行されるので、パスワードなどシークレットをgitに上げても大きな問題は無いが、パスワードをソースコード管理に入れないのは良い習慣である。

## よく使うコマンド

[このあたり](https://github.com/docker-library/docs/tree/master/mysql#how-to-use-this-image)を参考にするといろいろ書いてある。

Makefileに最低限のコマンドを記載した。

```sh
$ make
help:           Show this help.
up:             Up
down:           Down
logs:           Show logs
login:          login db
clean:          clean
mysql-client:   connet mysql from mysql cli
```

`docker compose exec db` のように、docker compose で起動したコンテナにサービス名を指定してアクセスすることができる。[^exec]

```sh
$ docker compose exec db /bin/bash
bash-4.4$
```

別のコンテナから、docker compose で起動したでMySQLのコンテナにアクセスする場合、docker compose で作成したbridge networksに接続すると、host dbとしてアクセスできる。[^net]
ここでは、[adminer](https://www.adminer.org/)を起動しMySQLにアクセスする。

```sh
$ docker run --rm -p 8080:8080 -e ADMINER_DEFAULT_SERVER=db --network backend_network adminer:4.8.1-standalone
```




[^mysql]: https://github.com/docker-library/mysql
  https://github.com/docker-library/docs/tree/master/mysql
[^user]: https://docs.docker.com/engine/reference/run/#user
  https://github.com/docker-library/docs/tree/master/mysql#running-as-an-arbitrary-user
[^bind]: https://docs.docker.com/storage/bind-mounts/
[^env]: https://github.com/docker-library/docs/tree/master/mysql#environment-variables
[^log]: https://github.com/docker-library/docs/tree/master/mysql#container-shell-access-and-viewing-mysql-logs
[^var]: https://docs.docker.com/compose/environment-variables/
  typical shell syntax https://manpages.debian.org/unstable/manpages-ja/bash.1.ja.html#%E3%83%91%E3%83%A9%E3%83%A1%E3%83%BC%E3%82%BF%E3%81%AE%E5%B1%95%E9%96%8B
[^dotenv]: https://github.com/direnv/direnv/blob/master/man/direnv-stdlib.1.md#dotenv-dotenv_path
[^source_env]: https://github.com/direnv/direnv/blob/master/man/direnv-stdlib.1.md#source_env-file_or_dir_path
[^gitignore]: https://git-scm.com/docs/gitignore
[^exec]: https://docs.docker.com/engine/reference/commandline/compose_exec/
[^net]: https://docs.docker.com/network/bridge/#differences-between-user-defined-bridges-and-the-default-bridge