# [chromium] Chromium にコントリビュートするための周辺知識

## Intro

Chromium にコントリビュートするためには、ソースコードを理解する以外にも、もろもろ必要な周辺知識がある。

ドキュメントはかなり整備されている方ではあるが、そのドキュメントにたどり着くのが難しい場合もある。

レビュアーなどが親切に教えてくれるものをローカルにメモしているが、それも散らばってきたため、ここにまとめることにする。

まずは初期状態で公開するが、どんどん更新していき、長くなっても分割しないで追記を繰り返そうと考えている。


## 関連サイト

始めて取り組もうとすると、まずどこを見ればわからないところから始まる。

似たようないくつかのサイトがあり、使い分けがされているからだ。

- code search
  - https://source.chromium.org/chromium/chromium/src
  - コードをインタラクティブに検索するためのサイト
  - Workspace 風の UI であり、シンボルがリンクなので捗る
  - Related File や Blame もできる
  - 右上の "View in Gitiles" で Gitiles に飛べる
- gitiles
  - https://chromium.googlesource.com/
  - Git のリポジトリがそのまま上がっている場所
  - ソースのリンクはこちらが使われることもある。
  - こちらから Code Search に飛ぶ方法はわからない。
  - 特定バージョン時点でのコードは以下で見られる
    - https://chromium.googlesource.com/chromium/src.git/+refs
- crbug
  - https://issues.chromium.org/issues?q=fetch
  - 元々は https://bugs.chromium.org だったが最近移行された
  - crbug とも呼ばれ以下で短縮できる
  - https://crbug.com/10000
  - 何かバグを見つけた場合もここから登録する
  - 作業をする場合もここから探す
- gerrit
  - https://chromium-review.googlesource.com/dashboard/self
  - レビューをするためのサイト
  - crrev とも呼ばれ、以下で短縮できる
  - https://crrev.com/c/10000
- chromium dash
  - https://chromiumdash.appspot.com/home
  - もともとは [omahaproxy](https://omahaproxy.appspot.com/) というサービスだったもの
  - ビルドやリリースに関する情報がまとまっている


### code search

- 検索クエリとして使える構文
  - https://developers.google.com/code-search/reference?hl=ja

例えば「ファイルパスじゃなくて中身に、全部小文字の "fetch" が出てくる `.cc` でテストじゃないやつを blink 以下で探す」はこんな感じ。

```
content:fetch case:y f:third_party/blink/renderer/core/fetch f:.cc -test
```

`lang:cpp` だと `.h` も入るので拡張子の方が絞れる。

よく使うもののおおよその階層を把握し、そこを絞ってからディレクトリ内検索する方が良い。

- `chrome/`
  - Chrome アプリ固有の機能
  - 拡張機能やオートフィル、ブックマークなど
- `content/`
  - タブ内で必要な機能
- `third_party/blink/`
  - レンダリングエンジン Blink
  - 筆者としては一番触るディレクトリ
- `url`
  - Google 謹製の URL パーサ
- `v8`
  - JS エンジンの V8

基本的に Chromium はマルチプロセスになっている。

親プロセスとして browser process があり、各タブを開くごとに独立した rendering process が開かれる。 rendering process と browser process は IPC しかできない。

これによって rendering process がサンドボックス化されている。つまり、インターネットの有象無象なコードを落として実行し、仮に rendering process が攻撃されても、そこから browser process は守られているため、 OS から情報を抜いたりはできない。

![chrome process architecture](chrome-process-architecture.png#720x405)

というあたりを把握しておくと検索しやすい。

両者を繋ぐ IPC が mojo だ。デバッグ中はだいたい mojo まで到達するとそこから辿れなくなる。(この辺を越えられるようになりたい)

ソースコードの歩き方を解説している記事が日英ともにちょいちょいあるが、割と大きなリネームがあったり、構造が変わったりしているので、記事の鮮度には注意が必要。


### crbug

何かバグを見つけた時に報告する先。

![crbug](crbug.png#4226x1350)

最近 Issue Tracker という新しいツールにマイグレートされたので、使い方がまだよくわからない。調べて出てくる crbug は大抵古い UI なので注意が必要。

- 入門ガイド
  - https://developers.google.com/issue-tracker/concepts/components?hl=ja

報告するぶんには、とりあえずわかってることを全部書いておけば、誰かしらがトリアージしてくれる。

探す上では、バグがどのコンポーネントに関連するかを示す Component を先に見つけると捗る。

```
Blink>Network>FetchAPI
Blink>PerformanceAPIs>ResourceTiming
...
```

また、関連する複数のバグは Hotlist というものでまとめられる。

例えば、 Hotlist-GoodFirstBug とか。

- Hotlist-GoodFirstBug
  - https://issues.chromium.org/issues?q=Hotlist-GoodFirstBug

ここでバグを見つけて、もしレビューがあったらそっちを見ると、どういうコードが入ったのかわかる。


### crrev

Git で upload したコードはここに入りレビューされる。この UI は慣れないと難しい。

![crrev](crrev.png#1872x864)

コントリビューションガイドを読んでおくといい。

- Chromium Docs - Contributing to Chromium
  - https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/contributing.md

とりあえずレビューを立てたら Description を書いて、コードをあげる。

Reviewers の下のペンボタンを押すと、コードのディレクトリの中にある OWNERS ファイルに書かれた人からサジェストされる。普通は先に issue があるはずなので、そこでコミュニケーションした人を選べば良い。

![review files](review-files.png#1466x1116)

選んだら Start Review すると初めてリクエストが送られる。これをしないと誰も見てくれない気がする。

crrev には Patchset という概念があり、これは複数コミットがあっても `git cl upload` した単位でつく。

この単位でレビューコメントが付き、それに対応していくことになる。

![review](review.png#1246x394)

レビューが付いたら、そこに対して REPLY でコメントを返すか、次の Patchset で直して、治ったら DONE にする。

コメントをつけたら、それだけで相手に通知がいくわけではない。コメントをつけたり DONE を押したら、必ず画面上部の REPLY を押す必要がある。これがないと Submit されないので、夜コメント書いて朝返事があるかなと思ったら REPLY 押し忘れてたみたいなことがあるので注意。

![reply](reply.png#770x246)

Rebase は UI 上からできるが、全部のコメントを一旦終えてから Rebase するのがマナーらしい。

Rebase が終わったら、 "CQ DRY RUN" する。これが CI でビルドと全テストを流すボタン。ただし、権限のある人にしかできないので、 Reviewer にやってもらうことになる。

![rebase-dry-run](rebase-dry-run.png#688x80)

全部終わると、 Code-Review +1 がもらえる。これがないとマージされない。

![lgtm](lgtm.png#1204x360)

もろもろ終わると自動でマージされる。


### chromium dash

リリースなどに関する情報が集まったダッシュボード。

マージされたコードがいつリリースされたかを知りたい場合、ここで知ることができる。

まず、マージされた Patchset のコミットハッシュを取得する。(crrev だと Patchset の横からコピーできる)

![patchset hash](patchset-hash.png#664x132)

それを Chromium Dash の Commits に入れれば情報が出る。

例えば以下なら。

- Rename InterestGroup API flag for common use and add flag for PARAKEET impl (3158266) · Gerrit Code Review
  - https://chromium-review.googlesource.com/c/chromium/src/+/3158266

これ。

- Chromium Dash
  - https://chromiumdash.appspot.com/commit/4359c5ebd238c93c22e69d369cbe813ae3081b6c

![commit landed](commit-landed.png#1398x188)

今回の場合は 96 でリリースされたことがわかる。

逆にここから Review や Bug にも飛べる。


## 公式の参考リソース

- docs - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:docs/
  - このディレクトリに色々ある
  - まずは [README.md](https://source.chromium.org/chromium/chromium/src/+/main:docs/README.md)
- C++ in Chromium 101 - Codelab
  - https://chromium.googlesource.com/chromium/src/+/HEAD/codelabs/cpp101/README.md
  - C++ のコードラボ
- Chrome University
  - https://www.youtube.com/playlist?list=PLNYkxOF6rcICgS7eFJrGDhMBwWtdTgzpx
  - 公式の教育ビデオコンテンツ


### 環境構築

Chromium は、一部を開発するにも、基本は全てをチェックアウトしてビルドする必要がある。

- Linux ビルド環境
  - https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md
- Mac ビルド環境
  - https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md

基本は書かれている通りやるだけ。

ビルドは、基本的に Linux が一番早い(ファイルシステムやプロセス生成の影響がでかい)らしいので、 OS 依存でない限りは Mac より Linux を用意する方が良さそう。

ちなみに Mac(2020 Core i7/32GB) だと。

- ネットワークによるが最初の sync だけで 4,5 時間
- Build は一晩
- Build 後はソース + バイナリで 100GB くらい

Google 社員は Reclient という分散ビルド環境を使っている(以前は Goma という環境だった)。これはコントリビュートを重ねてから申請するとアクセス権がもらえるらしい。それまでは手持ちのマシンで頑張るしかない。ちょっとでもビルドを早くするための細かいテクニックも書かれているので、全部やると良さそう。


### 実行

ビルド結果の実行は以下。

```sh
$ out/Default chrome
```

オプションは色々ある。(TODO: まとめる)


### デバッグ

開発者のほとんどがプリントデバッグだけで開発しているらしい。

基本はこれ。

```cpp
LOG(ERROR) << "Foo";
LOG(ERROR) << __FILE__ << "Foo"
```

レベルを分けることもできる

```cpp
// --enable-logging=stderr --v=1
DVLOG(1) << __FILE__  << "Foo
```

他にも色々用意されている。よく使う型なら良い感じに変換されるようになってる。

- logging.h - chromium/src/base - Git at Google
  - https://chromium.googlesource.com/chromium/src/base/+/refs/heads/master/logging.h

stack trace の取り方はこう。

```cpp
#include "base/debug/stack_trace.h"

base::debug::StackTrace().Print();
// or
LOG(ERROR) << base::debug::StackTrace();
```

詳細は以下。

- getting started with blink debugging
  - https://source.chromium.org/chromium/chromium/src/+/main:docs/website/site/blink/getting-started-with-blink-debugging/index.md

GDB を使うことも可能だが、はまりどころは多いらしい。

- debugging.md - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:docs/linux/debugging.md
  - `--no-sandbox` で sandbox を無効にして実効しないとうまくデバッグできないケースに注意。

VSCode でのステップ実行方法もある。

- Chromium Docs - Visual Studio Code Dev
  - https://chromium.googlesource.com/chromium/src/+/master/docs/vscode.md

これが動くなら理想。たまに落ちる。

docs 以下を debug で検索すると色々テクニックが出てくる。

- debug - Search
  - https://source.chromium.org/search?q=debug&sq=&ss=chromium%2Fchromium%2Fsrc:docs%2F


### テスト関連

- テストの実行方法
  - https://www.chromium.org/developers/testing/running-tests/
- Unittest の一覧
  - https://source.chromium.org/chromium/chromium/src/+/main:docs/testing/test_descriptions.md


### Flag

新しく入れた機能は、最初フラグの裏に隠されることが多い。

その場合は、以下のように有効にする。

```sh
chrome --enable-features=SubresourceWebBundle
```

この値は `*_features.json5` というファイルがいくつかあり、そこに書かれている。

- file:features.json5 - Search
  - https://source.chromium.org/search?q=file:features.json5&ss=chromium

よく見るのは、 renderer/platform のもの。

- runtime_enabled_features.json5 - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/platform/runtime_enabled_features.json5

`features.cc` の場合もあるらしい。

ある程度安定したら、 CLI フラグではなく chrome://flags に入る。

- about_flags.cc - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:chrome/browser/about_flags.cc

Experimental で Origin Trials が始まると、それも features.json5 で管理される。

```json
{
  name: "CompressionDictionaryTransport",
  base_feature: "none",
  origin_trial_feature_name: "CompressionDictionaryTransportV2",
  origin_trial_allows_third_party: true,
  public: true,
},
```

このフラグが外れる前は、 A/B テスト的に一部のユーザ(1% とか)から徐々に有効にしていく。これを Finch という。

Finch がどうコントロールされているかは外にはでてこないが、これが自分の Chrome でヒットしているかどうかは chrome://version に以下のクエリをつけると見られる。

- chrome://version/?show-variations-cmd

で表示される、一番下に `Command-line variations` が追加される。よくわらかないフィーマットでワンラインにされているが、これを雑に `,` や `*` で改行すると、有効になってる機能が確認できるだろう。


### Git

Chromium 用の Git の拡張が用意されており、それを用いてコントリビュートする。

- Chromium www.chromium.org Website - site/developers/gerrit-guide/index.md
  - https://chromium.googlesource.com/website/+/HEAD/site/developers/gerrit-guide/index.md

```shell
# Issue 番号で紐づける
$ git cl issue 123456

# 書いたコードを gerrit にアップする
$ git cl upload
```


## Tips

### IDL

WebIDL 相当のもの。

ここから python script で interface 付きの DOM API コードが生成される。

例えば `URL` の IDL は以下。

- url.idl - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/url/url.idl

```
// https://url.spec.whatwg.org/#url

[
    Exposed=(Window,Worker),
    ImplementedAs=DOMURL,
    LegacyWindowAlias=webkitURL
] interface URL {
    [RaisesException] constructor(USVString url, optional USVString base);

    static boolean canParse(USVString url, optional USVString base);

    [RaisesException=Setter] stringifier attribute USVString href;
    readonly attribute USVString origin;
    attribute USVString protocol;
    attribute USVString username;
    attribute USVString password;
    attribute USVString host;
    attribute USVString hostname;
    attribute USVString port;
    attribute USVString pathname;
    attribute USVString search;
    [SameObject] readonly attribute URLSearchParams searchParams;
    attribute USVString hash;

    USVString toJSON();
};
```


### sqlite3

色々なデータの格納に sqlite が使われている。

例えば Cookie は以下

TODO:

```
sqlite> .tables
sqlite> .schema
sqlite> select * from table
```


## WPT

Web Platform Tests は、各ブラウザが共通して実行する Web の単体テスト群のようなもの。

最近でいうと、 Interop は WPT の達成度合いを上げていこうという取り組みだったりする。

Chromium は WPT をリポジトリの中に入れており、 Web 標準の機能を実装する際はそのテストを直接 WPT にも追加してレビューに投げる。マージされたらそのテストは WPT 本体にもアップロードされるようになっている。

WPT の実行の仕方とテストの書き方も慣れが必要。


### 実行

WPT の実行は、公式では `wpt` コマンドが提供されている。

- wpt - Chromium Code Search
  - https://source.chromium.org/chromium/chromium/src/+/main:third_party/wpt_tools/wpt/wpt

しかし、Chromium の中では、この代わりに `/third_party/blink/tools` 以下のコマンドを使用するっぽい。

自分がビルドした Chromium のインスタンスで、特定の WPT を実行する。

```shell
$ third_party/blink/tools/run_wpt_tests.py -t Default -p chrome third_party/blink/web_tests/external/wpt/resource-timing/content-encoding.https.html -vv
```

これで、該当の HTML がブラウザ上で実行され、テストが走るイメージ。

手動で実行して試したい場合は、サーバだけ起動してアクセスする。

```shell
$ ./third_party/blink/tools/run_blink_wptserve.py
Server running on http://localhost:8001
Server running on http://localhost:8081
Server running on http://localhost:8082
Server running on http://localhost:8093
Server running on https://localhost:8444
Server running on https://localhost:8445
Server running on https://localhost:8446
Server running on https://localhost:8447
Server running on https://localhost:9000
Server running on ws://localhost:9001
Server running on wss://localhost:9444
WebTransportH3 server running on https://localhost:11000
```

とりあえず 8001 ポートにアクセスすれば試せる。

テスト用のドメインとしては `web-platform.test` などのドメインが使われる。

これを解決できないと実行できないテストがある場合は、 `/etc/hosts` に追加する必要があるが、その自動構成スクリプトは以下にある。

- Command-Line Arguments - web-platform-tests documentation
  - https://web-platform-tests.org/running-tests/command-line-arguments.html#make-hosts-file


### テストサーバ

fetch などでサーバを叩いたりするテストのために、 mock server を書く方法がいくつかある。

- Server Features - web-platform-tests documentation
  - https://web-platform-tests.org/writing-tests/server-features.html

まず、普通にファイル (`/example/text.html`) を置けば、それは静的ファイルとしてアクセスできる。

これにヘッダをつけたい場合は、 .headers ファイルを作る(`/example/test.html.headers`)

```
Access-Control-Allow-Origin: *
```

.asis ファイルを作ると、その中に書いたレスポンスがまるっとそのまま返る。(Apache As-Is という仕様らしい)

```http
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 5

hello
```

動的にレスポンスを生成したい場合は wptserve という Python のサーバを書く。

```py
def main(request, response):
    content_type = request.GET.first('content-type')
    response.headers.set(b'content-type', content_type)
    response.content = b'hello'
```

書き方は色々あるが、だいたい見ればわかるので、近くのファイルを参考にする。


### HTTPS

注意点として、もしそのファイルに HTTPS でアクセスしたい場合は、 `${name}.https.${ext}` のように、ファイル名に https を入れる必要があります。

特に、 HTTPS でしか動かない機能のテストはこれを忘れると落ちるので注意。

その上で HTTP/2 が必要なら `${name}.h2.${ext}` とするなど、他のフラグもある。


## Outro

TODO: 思い出したら色々追記