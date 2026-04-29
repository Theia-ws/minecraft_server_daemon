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
<tr><th></th><th>FreeBSD</th><th>Systemd</th></tr>
<tr><td>curl</td><td>✔</td><td>✔</td></tr>
<tr><td>git</td><td>✔</td><td>✔</td></tr>
<tr><td>jre25</td><td>✔</td><td>✔</td></tr>
<tr><td>tmux</td><td>✔</td><td>✔</td></tr>
<tr><td>sudo</td><td>✔</td><td>✔</td></tr>
</table>
<h3>実行ユーザ</h3>
<p>このデーモンはroot権限により起動処理が行われ、サーバ本体はユーザが設定ファイルで指定したユーザによって実行する。</p>
<p>凡例<br/>
✔:自動作成　❌:ユーザによる作成が必要</p>
<table>
<tr><th></th><th>FreeBSD</th><th>Systemd</th></tr>
<tr><td>デフォルトユーザ名</td><td>minecraft</td><td>minecraft</td></tr>
<tr><td>自動作成</td><td>✔</td><td>✔</td></tr>
</table>
<h3>対応コマンド</h3>
<p>凡例<br/>
✔:対応　❌:非対応</p>
<table>
<tr><th></th><th>FreeBSD</th><th>Systemd</th><th>機能説明</th></tr>
<tr><td>build</td><td>✔</td><td>✔</td><td>サーバとして使用するBukkit、Spigot、又は、PaperMCをビルドします。</td></tr>
<tr><td>command</td><td>✔</td><td>✔</td><td>Minecraftサーバのサーバコンソールでコマンドを実行します。</td></tr>
<tr><td>remove</td><td>✔</td><td>✔</td><td>デーモンのアンインストールを行います。<br/>ワールドデータは削除しません。</td></tr>
<tr><td>restart</td><td>✔</td><td>✔</td><td>デーモンを再起動します。</td></tr>
<tr><td>start</td><td>✔</td><td>✔</td><td>デーモンを起動します。</td></tr>
<tr><td>status</td><td>✔</td><td>✔</td><td>デーモンを起動状態を表示します。</td></tr>
<tr><td>stop</td><td>✔</td><td>✔</td><td>デーモンを停止します。</td></tr>
</table>
<h3>動作確認OS</h3>
<table>
<tr><th>FreeBSD</th><th>Systemd</th></tr>
<tr><td>FreeBSD 15</td><td>Alma Linux 10(SELnuxの無効化が必要)<br />Utuntu Server 24.4<br />Debian 13.4</td></tr>
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
<li>TMUX_PATH<br/>tmuxコマンドのパスを指定します。(ディストリビューション付属のものを使う場合は不要)</li>
<li>TMUX_NAME<br/>Minecraftサーバを実行するtmux名を指定します。</li>
<li>JAVA_PATH<br/>javaコマンドのパスを指定します。(ディストリビューション付属のものを使う場合は不要)</li>
<li>MIN_MEMORY<br/>Minecraftサーバを実行するJVMに割り当てる最小メモリを指定します。</li>
<li>MAX_MEMORY<br/>Minecraftサーバを実行するJVMに割り当てる最大メモリを指定します。</li>
<li>JAVA_PATH<br/>Minecraftサーバとして実行するJARファイルのパスを指定します。ビルド機能によってこのパスに配置されたJARファイルを更新します。</li>
<li>SERVER_TYPE<br/>使用するサーバタイプを指定します。craftbukkit、spigot、又は、papermcが設定できます。</li>
<li>SERVER_REVISION<br/>Minecraftサーバーのリビジョンを指定します。このバージョンに基づいて、ビルド機能がサーバをビルドします。</li>
<li>DEFAULT_STOP_WATE_TIME<br/>MinecraftサーバにSTOPコマンドを送る際に予告メッセージを送る時間を指定します。停止するまでの残り時間が30秒の倍数の時間になった時、及び、10秒以下になった時に予告メッセージを表示します。</li>
<li>eula<br/>By changing the setting below to TRUE you are indicating your agreement to our EULA (<a href="https://account.mojang.com/documents/minecraft_eula">https://account.mojang.com/documents/minecraft_eula</a>).<br/>MojangのEULAに同意しtrueに設定する事でインストール直後に自動的にサーバが起動します。</li>
</ol>
<h3>インストール</h3>
<p>FreeBSDの場合「./install.freebsd.sh」、Systemdの場合「install.systemd.sh」を実行する。</p>
<h3>既知の問題点</h3>
<ol>
<li>RHEL系環境でSELinuxの無効化が必要。</li>
<li>スクリプト実行時に不要なメッセージが表示される。</li>

</ol>
<h3>今後やりたい事</h3>
<ol>
<li>sudoの排除</li>
<li>tmuxの排除</li>
<li>インストーラの一本化</li>
</ol>