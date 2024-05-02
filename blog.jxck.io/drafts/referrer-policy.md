# [referer][security] Referrer-Policy の制限を強めると安全になるという誤解

## Intro

`Referrer-Policy` は、送信される `Referer` の値を制御することが可能だ。

このヘッダの副次的な効果がよく理解していないと、「`no-referer` にして送らないのが最も安全だ」という誤解を生むことになる。

この記事は、前提として前回の記事の「リクエストの出自をチェックすることは現代の実装のベースプラクティスである」という点を踏まえている。

- 令和時代の API 実装のベースプラクティスと CSRF 対策 | blog.jxck.io
  - https://blog.jxck.io/entries/2024-04-26/csrf.html


## Referer とアナリティクス

Referer は、リクエストに対してその前のページの URL を送るところかた始まった。

```http
GET / HTTP/1.1
Host: example.com
Content-Type: text/html
Referer: https://blog.jxck.io/entries/2099-12-12/referer.html
```

この情報によって、 example.com はユーザが blog.jxck.o の記事から遷移してきたことがわかる。

これが検索エンジンの URL であれば、検索からの流入であることがわかり、 SNS であれば拡散されたポストからであることがわかる。

従って、多くの場合はマーケティングてきな用途が想像されやすく、実際アナリティクスなどはこの情報を重要視している。


## Referer による情報漏洩

例えば、ユーザが VPN などでアクセスする社内のポータルに貼られた URL から遷移した場合、以下のように外部からアクセスできない URL が付与されることになる。

```http
GET / HTTP/1.1
Host: example.com
Content-Type: text/html
Referer: https://wiki.company.example/secret/new-product.html
```

URL は雄弁であるため、そこから読み取れる情報は決して少なく無い。特に新製品の名前がパスに使われれば、未公開の情報が取得できるかもしれない。

もし Issue トラッカーが、タイトルの内容をそのまま URL に入れるタイプのものであれば、まるっと脆弱性情報が漏洩する可能性もある。

```
GET / HTTP/1.1
Host: blog.jxck.io
Content-Type: text/html
Referer: https://issues.company.example/bugs/csrf-reported-on-admin-page.html
```

これは、どんなにそのサイトを VPN や認証などで隠しても、閲覧社のブラウザを経由して送られるため、意図しない漏洩に繋がる可能性もあるのだ。


## Referrer-Policy

これを制御するために Referrer-Policy が整備された。

このポリシーは基本的に送信する条件と、その粒度を制御できる。基本的には 3 つの観点がある。

- 送る情報は Full Path か Origin のみか
  - Full Path: `https://example.com/path/to/html`
  - Origin: `https://example.com`
- 別 Origin に送るのか
- HTTP (平文通信)で送るのか

さて、前述のようなリスクを考えると、多くの人はこう考えるだろう。

> Referrer は一切送らないのがセキュリティ上のプラクティスだ。つまり必ず `no-referrer` を設定すべきだ。

いわゆるセキュリティ専門家のような人も、それを推奨している場合がある。

**それは勘違いだ。**


## Referrer と Origin

前回の記事で、リクエストに Origin ヘッダが付与されるようになったことの、セキュリティ対策への効能について解説した。

- 令和時代の API 実装のベースプラクティスと CSRF 対策 | blog.jxck.io
  - https://blog.jxck.io/entries/2024-04-26/csrf.html

これまで「どこからリクエストされたものかわからない」ことが原因で発生していた CSRF のような攻撃は、 Origin ヘッダが付与されることで根本的に対策することが可能になった。逆を言えば、「*そのために人類は Origin ヘッダというリクエストの出自を知る解決策を手に入れた*」という話だった。

ところが、リクエストの出自を知る方法は、 Origin 以前からあった。それが Referer だ。

では、なぜ Referer をそのまま活用しないのかというと、「Referer はプライバシーの侵害につながるのでブラウザの設定で無効にする」というプラクティスが、特にハイリテラシー層に十分に浸透していたからだ。ブラウザもその機能をプライバシー重視であることのコマーシャルと共に提供し、無いブラウザでも探せばだいたいは拡張が手に入る状況だ。HTTPS が一般化する前は、企業内 Proxy などが自動的に Referrer ヘッダを落としていた時代もある。

その状況で、 Referer に依存してリクエストのフィルタリングを行うことはできない。そこで、 CORS の策定時に「最低限の出自情報」として Origin ヘッダが定義された。 Origin には Path 情報がないため、最小限の情報のみが提供される。そして CORS で連携するというのは、 `Access-Control-Allow-Oring` でその Origin との連携を明示的に許可することで実現するものであり、連携情報としての Origin 提供は漏洩とは見做されない(それも許せないなら、連携は使わないべき)という仕組みになっている。 Referer を落としているユーザであっても、新設された Origin は正しく送られていると想定すべきであり、それが送られてないのであれば、安全な連携は提供できないとして扱うべきなのだ。

その Origin ヘッダを、 Form の POST でも提供するようにし、「POST はどこから来たのか?」を確認することで「意図した連携」なのか「意図しない連携(これが CSRF の実態」なのかを識別できるように、やっと仕様を整備し互換性を担保して今にいたるのだ。つまり、現行の Web のルール上「Origin を確認しないということは、セキュアな実装ができてない」とみなして良く、このインフラとしての Origin ヘッダは慎重に扱われるべきものなのだ。


## RFC 7231 における Referer の扱い

HTTP/1.1 の RFC が更新された際に、 Referer の節には以下のような注意書きが追加された。

> Some intermediaries have been known to indiscriminately remove Referer header fields from outgoing requests.
> This has the unfortunate side effect of interfering with protection against CSRF attacks, which can be far more harmful to their users.
> Intermediaries and user agent extensions that wish to limit information disclosure in Referer ought to restrict their changes to specific edits,
> such as replacing internal domain names with pseudonyms or truncating the query and/or path components.
> An intermediary SHOULD NOT modify or delete the Referer header field when the field value shares the same scheme and host as the request target.
>
> 一部の中継者は、外向けのリクエストから Referer ヘッダを無差別に除去することが知られている。
> これは CSRF 攻撃に対する保護に干渉するような，望ましくない副作用を及ぼし、それは、ユーザにとってはるかに有害となる。
> Referer 内への情報開示を制限したい中継者/UA 拡張はそれらの変更を、内部ドメイン名を匿名化したり、 query や path を切り落とすなどの、特定の編集に制約するべきである。
> 中継者は、ヘッダがリクエストターゲットと同じ scheme / host であれば、 Referer ヘッダを改変したり削除するべきでない。
>
> --- https://www.rfc-editor.org/rfc/rfc7231.html#section-5.5.2

もちろん消すべき時もあるが、なんでもかんでも「消せばいい」とは限らないということが、この文章からもわかるだろう。

特に最後の一行は重要だ。 Same Origin でのリクエストであれば、サイト内の回遊などログでもなんでも自明であるため、わざわざ Referer を落とすことのメリットはない。むしろ、それによって「リクエストの出自が検証できなくなる == 外からの工作されたリクエストではない」ということがわからなくなるため、セキュリティ上はマイナスにしか作用しないのだ。

ところが、「とはいえ Referer ではなく Origin をチェックするから Referrer-Policy は関係ないのでは?」と思うかもしれない。

ここにもう 1 つの落とし穴があるのだ。


## Referrer-Policy: no-referrer

`Referer-Policy: no-referrer` は、それを付与することでブラウザが一切の Referer を送らなくなる。つまり、遷移先に対して遷移元の URL が何であったかは、全て送られなくなるのだ。Same Origin であってもだ。

実はこのディレクティブには副作用がある。

```
To append a request `Origin` header, given a request request, run these steps:

1. Let serializedOrigin be the result of byte-serializing a request origin with request.
2. If request's response tainting is "cors" or request's mode is "websocket", then append (`Origin`, serializedOrigin) to request's header list.
3. Otherwise, if request's method is neither `GET` nor `HEAD`, then:
  1. If request's mode is not "cors", then switch on request's referrer policy:
    - "no-referrer": Set serializedOrigin to `null`.
    - "no-referrer-when-downgrade"
    - "strict-origin"
    - "strict-origin-when-cross-origin": If request's origin is a tuple origin, its scheme is "https", and request's current URL's scheme is not "https", then set serializedOrigin to `null`.
    - "same-origin": If request's origin is not same origin with request's current URL's origin, then set serializedOrigin to `null`.
    - Otherwise: Do nothing.

Note: A request's referrer policy is taken into account for all fetches where the fetcher did not explicitly opt into sharing their origin with the server, e.g., via using the CORS protocol.

--- https://fetch.spec.whatwg.org/#append-a-request-origin-header
```

つまり、 CORS のように明示的に Origin を確認させる場合はそちらを優先するが、 CORS でなくかつ GET/HEAD でない場合は、 `Referrer-Policy: no-referrer` を受けていた場合、 `Origin: null` にしてしまうのだ。

そのケースが何かというと、まさしく `<form method=post>` のことだ。

安直に `Referrer-Policy: no-referrer` にすると、 Referer ヘッダを送らなくなるだけではなく、 Origin ヘッダも `null` にしてしまい、同じサイトからのリクエストなのに、その事実が Origin から判断できなくなるのだ。

まあ、最近のサービスは `fetch()` 以外でリクエストを送ることも減ってきてはいるかもしれない。一方で、 Progressive Enhancement として生の form によるリクエスト「も」使えるようにする場合もある。そうでなくても、例えばレガシーなアプリを Origin を検査する簡単なミドルウェアや WAF/CDN 相当のレイヤ追加だけで格段に安全にできるものを、「Referrer は送らない方が安全」という勘違いで台無しにし得るのだ。


## Referrer-Policy 値の選定

以上を踏まえて `Referrer-Policy` のディレクティブを確認してみよう。

- no-referrer
- no-referrer-when-downgrade
- origin
- origin-when-cross-origin
- same-origin
- strict-origin
- strict-origin-when-cross-origin
- unsafe-url

しかし、全部を覚える必要はない。

重要なのは以下の 3 つの観点だ。

- 送るのは Full Path か Origin か
- 送る対象は Same Origin か Cross Origin か
- HTTP でも送るか

ここまでの話を適用すると、以下がベースとなる。

- Same Origin なら Path が送られても問題はない
- 平文通信では送るべきではない

この上で 「*Cross Origin への送信*」をどうするかだけを比較すると、候補は以下に絞られる。

- no-referrer
  - 常に送らない
- no-referrer-when-downgrade
  - 常に Path を送る
  - downgrade では送らない
- strict-origin-when-cross-origin
  - Same Origin の時は Path
  - Cross Origin の時は Origin
  - downgrade では送らない
- same-origin
  - Same Origin の時だけ Path

従来、ブラウザのデフォルトは `no-referrer-when-downgrade` だった。しかし、 Cross Origin にも Full Path を送るのはエントロピーが高くトラッキングベクタにもなり得る。一方で、完全に送らなければ、出自チェックに使えなくなる。そこで、従来の Web における「外部への情報提供」と「自サイト内での出自検証」を両立しつつ、前者には Origin だけ、後者には Full Path を送るという最もバランスが取れた設定として、 `strict-origin-when-cross-origin` を新しくブラウザのデフォルトにする流れがあった。 2018 年ごろの話だ。

- Referrer-Policy によるリファラ制御 | blog.jxck.io
  - https://blog.jxck.io/entries/2018-10-08/referrer-policy.html

したがって、多くのサイトにとっては、このデフォルトの値が十分にバランスが取れ、互換性の面でも問題を起こしにくい値となっていることがわかる。

その上で、もし「Origin であっても外部に漏洩させたくない」という、企業内サイトなどであれば、選択すべきは `no-referrer` ではなく `same-origin` なのだ。これであれば、外に情報は出ず、内部でのリクエストはきっちりと出自の確認ができる。 Origin ももちろん消えない。


## Outro

「とにかく Referer は送らないのが安全だ」という勘違いは、「リクエストに出自情報が載るのは漏洩だ」という短絡的な勘違いに起因していることが分かっただろう。

むしろ、これまで欠落していた出自を適切に送り、サーバはそれを確認することで安全を担保する、という状態を実現するために Web プラットフォームは長い時間をかけて「デフォルトで安全な状態」を実現し今に至るのだ。

その理由をよく分かってない状態で、「強く制限すれば安全になる」という思い込みが、現代のセキュアな実装のための基盤を脆くしている可能性には、十分に注意したい。