<meta charset="utf-8"/>


# minecraft_server_daemon
<p>This script that registrers Minecraft server as system daemon.</p>
<h2>対応機能</h2>
各バージョンが対応している機能を説明します。
<h3>依存パッケージ</h3>
<p>このデーモンを実行するには下表のパッケージが必要となる。</p>
<p>凡例<br/>
✔:自動インストール　❌:ユーザによるインストールが必要　➖：依存なし</p>
<table>
<tr><th></th><th>FreeBSD</th><th>FreeBSD<br/>ZFS(推奨)</th><th>Systemd</th><th>Initd</th></tr>
<tr><td>curl</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td></tr>
<tr><td>git</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td></tr>
<tr><td>jre17</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td></tr>
<tr><td>screen</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td></tr>
<tr><td>sudo</td><td>➖</td><td>✔</td><td>✔</td><td>✔</td></tr>
</table>
<h3>実行ユーザ</h3>
<p>このデーモンはroot権限により起動処理が行われ、サーバ本体はユーザが設定ファイルで指定したユーザによって実行する。</p>
<p>凡例<br/>
✔:自動作成　❌:ユーザによる作成が必要</p>
<table>
<tr><th></th><th>FreeBSD</th><th>FreeBSD<br/>ZFS(推奨)</th><th>Systemd</th><th>Initd</th></tr>
<tr><td>デフォルトユーザ名</td><td>minecraft</td><td>minecraft</td><td>minecraft</td><td>minecraft</td></tr>
<tr><td>自動作成</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td></tr>
</table>
<h3>対応コマンド</h3>
<p>凡例<br/>
✔:対応　❌:非対応</p>
<table>
<tr><th></th><th>FreeBSD</th><th>FreeBSD<br/>ZFS<br/>(推奨)</th><th>Systemd</th><th>Initd</th><th>機能説明</th></tr>
<tr><td>backup</td><td>❌</td><td>✔</td><td>❌</td><td>❌</td><td>最新のボリュームスナップショットからバックアップファイルを作成します。</td></tr>
<tr><td>build</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>サーバとして使用するBukkit、Spigot、又は、PaperMCをビルドします。</td></tr>
<tr><td>command</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>Minecraftサーバのサーバコンソールでコマンドを実行します。</td></tr>
<tr><td>remove</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>デーモンのアンインストールを行います。<br/>ワールドデータは削除しません。</td></tr>
<tr><td>restart</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>デーモンを再起動します。</td></tr>
<tr><td>snapshot</td><td>❌</td><td>✔</td><td>❌</td><td>❌</td><td>ワールド保存先のボリュームのスナップショットを作成します。</td></tr>
<tr><td>start</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>デーモンを起動します。</td></tr>
<tr><td>status</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>デーモンを起動状態を表示します。</td></tr>
<tr><td>stop</td><td>✔</td><td>✔</td><td>✔</td><td>✔</td><td>デーモンを停止します。</td></tr>
</table>
<h3>動作確認OS</h3>
<table>
<tr><th>FreeBSD</th><th>FreeBSD<br/>ZFS(推奨)</th><th>Systemd</th><th>Initd</th></tr>
<tr><td>FreeBSD 13</td><td>FreeBSD 13</td><td>Alma Linux 9(SELnuxの無効化が必要)<br />Utuntu Server 20.4<br />Debian 11.3</td><td>No Test</td></tr>
</table>
<h2>インストール手順</h2>
<h3>事前準備</h3>
<p>この手順はSELinuxがインストールされている環境で必要になります。</p>
<ol>
<li>SELinuxを無効にします。</li>
</ol>
<h3>configの設定</h3>
<p>インストールフォルダ直下のconfigに設定します。</p>
<ol>
<li>MINECRAFT_SERVER_SERVICE_NAME<br/>システムに登録するサービス名を指定します。単一のサーバで複数のMinecraftを起動する場合変更してください。</li>
<li>MINECRAFT_SERVER_EXECUTE_USER<br/>Minecraftサーバを実行するユーザ名を指定します。Initd、又は、Systemdをインストールする場合、事前準備で用意したユーザ名を指定してください。</li>
<li>MINECRAFT_SERVER_EXECUTE_GROUP<br/>Minecraftサーバを実行するグループ名を指定します。Initd、又は、Systemdをインストールする場合、事前準備で用意したユーザのグループ名を指定してください。</li>
<li>MINECRAFT_SERVER_ROOT<br/>サーバ実行時のルートディレクトリを指定します。このディレクトリ配下にWorldやホワイトリストが保存されます。</li>
<li>CURL_PATH<br/>curlコマンドのパスを指定します。(ディストリビューション付属のものを使う場合は不要)</li>
<li>SCREEN_PATH<br/>screenコマンドのパスを指定します。(ディストリビューション付属のものを使う場合は不要)</li>
<li>SCREEN_NAME<br/>Minecraftサーバを実行するスクリーン名を指定します。</li>
<li>JVM_PATH<br/>javaコマンドのパスを指定します。(ディストリビューション付属のものを使う場合は不要)</li>
<li>MIN_MEMORY<br/>Minecraftサーバを実行するJVMに割り当てる最小メモリを指定します。</li>
<li>MAX_MEMORY<br/>Minecraftサーバを実行するJVMに割り当てる最大メモリを指定します。</li>
<li>JAR_PATH<br/>Minecraftサーバとして実行するJARファイルのパスを指定します。ビルド機能によってこのパスに配置されたJARファイルを更新します。</li>
<li>SERVER_TYPE<br/>使用するサーバタイプを指定します。craftbukkit、spigot、又は、papermcが設定できます。</li>
<li>SERVER_REVISION<br/>Minecraftサーバーのリビジョンを指定します。このバージョンに基づいて、ビルド機能がサーバをビルドします。</li>
<li>DEFAULT_STOP_WATE_TIME<br/>MinecraftサーバにSTOPコマンドを送る際に予告メッセージを送る時間を指定します。停止するまでの残り時間が30秒の倍数の時間になった時、及び、10秒以下になった時に予告メッセージを表示します。</li>
<li>eula<br/>By changing the setting below to TRUE you are indicating your agreement to our EULA (<a href="https://account.mojang.com/documents/minecraft_eula">https://account.mojang.com/documents/minecraft_eula</a>).<br/>MojangのEULAに同意しtrueに設定する事でインストール直後に自動的にサーバが起動します。</li>
</ol>
<h3>config.zfsの設定</h3>
<p>FreeBSD ZFSの場合のみ設定します。インストールフォルダのfreebsd.zfs/config.zfsに設定します。</p>
<ol>
<li>WROLD_PUT_PEARENT_POOL<br/>ワールドを保存する親zpoolを指定します。FreeBSDをZFSのルートストレージでインストールした時の初期値になっています。</li>
<li>SNAPSHOT_TARGET_WORLD<br/>スナップショットを作成する対象となるワールド名を指定します。地上、ネザー、エンドそれぞれに指定する必要がります。ワールドの指定数に上限はありません。[WROLD_PUT_PEARENT_POOL]/[MINECRAFT_SERVER_SERVICE_NAME_SNAPSHOT]_[SNAPSHOT_TARGET_WORLD]の形式でZFSボリュームを作成します。WROLD_PUT_PEARENT_POOL=zpool、MINECRAFT_SERVER_SERVICE_NAME_SNAPSHOT=minecraft_server、SNAPSHOT_TARGET_WORLD=worldの場合、「zpool/minecraft_server_world」となります。Multivirse等マルチワールドPlug-inを使用している場合、インストール時に設定しなければZFSボリュームの自動作成は行われません。</li>
<li>MAX_NUMBER_OF_SNAPSHOT<br/>スナップショットの上限数を指定します。上限を超えた場合、古いスナップショットから削除されます。</li>
<li>SAVE_BEFORE_SNAPSHOT<br/>スナップショット前のセーブを行うか行わないか(true=する、false=しない)。定期的なセーブを行っている場合はfalseにして良い。</li>
<li>SAVE_WAITE<br/>save-allコマンドにセーブ待機を行う時間。短すぎる時間を設定すると破損したワールドをバックアップする事になる為適切な時間を設定する事。</li>
<li>BACKUP_DIR<br/>バックアップを出力するディレクトリを指定します。</li>
<li>MAX_NUMBER_OF_BACKUP<br/>バックアップの上限数を指定します。上限を超えた場合、古いバックアップから削除されます。</li>
</ol>
<h3>インストール</h3>
<p>FreeBSDの場合「./install.freebsd.sh」、FreeBSD ZFSの場合「./install.freebsd.zfs.sh」、Initdの場合「install.initd.sh」、Systemdの場合「install.systemd.sh」を実行する。</p>
<h3>既知の問題点</h3>
<ol>
<li>RHEL系環境でOSを再起動した際、シャットダウン予告メッセージを表示せずに終了する。（同じSystemdを使うUbuntuでは起きないので原因はよくわからない）<br/>回避法:サーバOSシャットダウン時は「systemctl stop minecraft_server」→「shutdown -r now」の順序で実行する。</li>
<li>RHEL系環境でSELinuxの無効化が必要。</li>
<li>スクリプト実行時に不要なメッセージが表示される。</li>
<li>Minecraft 1.14以降craftbukkitをインストールできない。</li>

</ol>
<h3>今後やりたい事</h3>
<ol>
<li>sudoの排除</li>
<li>screenの排除</li>
<li>インストーラの一本化</li>
</ol>