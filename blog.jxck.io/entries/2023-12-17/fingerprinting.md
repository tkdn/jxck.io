# [cookie][3pca] 3PCA 17 日目: Fingerprinting

## Intro

このエントリは、 3rd Party Cookie Advent Calendar の 17 日目である。

- 3rd Party Cookie のカレンダー | Advent Calendar 2023 - Qiita
  - https://qiita.com/advent-calendar/2023/3rd-party-cookie

今日は、 Cookie に頼らない Tracking 手段としての、 Fingerprinting について解説する。


## Fingerprinting

3rd Party Cookie が無くても、トラッキングできると謳う製品の大半は、 Fingerprinting に依存している可能性が高い。

Fingerprinting は、ブラウザから取得できる情報をかき集めることで、ユーザごとに微妙に違う部分を手がかりに、ユーザを区別するという手法全般を指す。

この手法の精度は、いかにエントロピーの高い情報をブラウザから取得できるかにかかっている。そして、そのベースとなる情報は IP と User-Agent だろう。

IP だけでもかなり絞り込めはするが、同一ネットワークにいると同じ IP をポートを分けて使い回したり、時間が経つと別の人に割り当てられたりする。つまり IP のエントロピーは高いが、それのみで完璧な "区別" を実現できるとはいいがたい。

`User-Agent` 文字列は、使ってるマシンやブラウザ、そのバージョンなど細かい情報が入ってるため、同じネットワークにいても、 使っている OS やブラウザが違うと異なる値になる。

従って、大抵はこの 2 つをベースにし、さらに情報を付加することで、精度を高めていくことになる。

追加の情報として用いられるのは、例えば以下のようなものだ。

- `Accept-Language` の設定言語
- ローカルに保存されてるフォント情報
- 接続されたカメラや USB などのデバイス情報
- WebRTC や Canvas などエントロピーの高い情報が取得可能な API のコール結果
- ブラウザ特有や、ユーザ設定によるリクエストヘッダ

こうした Fingerprinting を防ぐ実装も、続々とブラウザに入っている。


### IP の秘匿

まず Apple が公開した IP への対応が、 Private Relay だ。これは Proxy を経由することで、サーバに見えるクライアントの IP を Proxy の IP に変えてしまうというものだ。発想自体は Tor と近い。

インフラを利用するため有料ではあるが、 IP さえ変わってしまえば、 Fingerprinting についてはほとんど解決といってもいいレベルだろう。

Mozilla や Brave は VPN を提供することで同等のことを実現している。

また、 IP の秘匿を標準化するために、 IETF では OHTTP という仕様の標準化作業を行っており、 Chrome や Firefox が Proxy としての Fastly などと組んで対応していく予定を公開している。

注意点として、IP の置き換えもまた、さまざまなユースケースに影響を与える。

例えば、ユーザの接続している国や地域は IP ベースで判断されることが多く、これはアクセス管理や、前述した GDPR の EU 判定などに使われる。こうした緩やかに国や地域を知ることができるよう、 Private Relay は IP のリストを公開し、その情報は変わらないように情報提供がされている。

もう一つは、犯罪対策だ。何かサイバー犯罪が起こった場合、犯人の特定は IP をプロバイダに問い合わせることで突き止めることが多いが、 Proxy が挟まるとそれが困難になる。この問題がどのように対応されていくのかは、筆者もずっと気にしてるが、まだ明確な指針は把握してない。


## User-Agent String Reduction

`User-Agent` はそもそも情報量が多すぎることが度々問題になっている。

元々は、当時使われていた HTML の `<frame>` が、 Netscape では対応されていたが、 Mosaic は対応していなかったことに起因する。そこで Web 開発者は、 Netscape か Mosaic かで分岐し `<frame>` の出し分けをしていた。

Netscape は Mosaic + Killer = Mozilla の意味で `Mozilla/1.0 (Win3.1)` という UA を送っていたため、以下のようなコードがデプロイされていたのだ。

```js
function frame_supported(user_agent) {
  if (user_agent.includes("Mozilla")) {
    return true
  } else {
    return false
  }
}
```

そこに後発の IE が登場した時、 IE は `<frame>` に対応しているにもかかわらず `MSIE/1.0` などと送っては、上のコードが False になる。そこで以下のような値を送り、 Netscape のふりをする必要があった。

```
Mozilla/1.22 (compatible; MSIE 2.0; Windows 95)
```

そうやって嘘を重ねた結果、今日に至る非常に長い UA 文字列が出来上がったのだ。

しかし、今では機能に対する分岐は Feature Detection が基本になるため、 UA の蓄積は一掃したい負債でもあった。そこで、今ではこのヘッダのエントロピーを下げていくための取り組みが始まっている。

Safari の場合は Version の値などを固定していくとで、以降のバージョンで文字列の変化する部分を減らすという "Freezing User-Agent" という取り組みが始まっている。もちろん、細かいバージョンが取れなくなると困るケースもあるが、大抵は特定バージョンのバグに起因する分岐であり、リリースサイクルが短くなったことでその影響も小さくなっている。

他のブラウザも概ね同意しており、 UA の代替としてもっと正確な情報を必要に応じて必要なだけ取る `Sec-CH-UA` を仕様化し、 Chrome を筆頭に対応が進んでいる。これは、デフォルトのいくつか以外は勝手には送られず、またブラウザも絞った情報しか出さないといったことで、 UA のようなことが起こらないようにしている。


## その他 API

特に Fugu 以降登場した、デバイスに接続する系の API は、そのデバイスの情報を取得することで、精度を高めることができてしまう。

また、Audio/Video のようにコーデックの対応が OS ごとに異なるものや、Local Font Access のようにユーザのカスタマイズ結果が取得できるような場面も、対象となる。

このように、 Web の API が OS やデバイスの情報にアクセスする API を増やせば増やすほど、 Web でできることが増える一方、 Fingerprinting のリスクが高まってしまうというトレードオフがあるのだ。

基本的に標準化の段階では、 Fingerprinting ベクターになるエントロピーの高い情報が取得できないかどうかは、必ずレビューされる。そして、取得がやむを得ない場合でも、例えばユーザに Prompt を表示して権限を取得するとか、情報の一部をマスキングするとか、さまざまな工夫がなされている。

対応方法は API によってまちまちだが、もし標準化で提案された方法がリスクを下げきれてない場合は、その API を実装しないブラウザもある。

デバイスに関わるような低レベル API の実装が普及しないのは、こういった背景もあるのだ。