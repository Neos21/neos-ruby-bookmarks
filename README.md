# Neo's Ruby Bookmarks

Ruby 製のオレオレブックマーク。


## 機能

- パスワード認証により、管理者だけが管理・閲覧できる、オリジナルのブックマーク。Pocket (Read It Later) 的に「読んだら削除する」使い方を想定
- ブックマークはテキストファイルに保存する


## 設定

`index.rb` の `定数` 部分を自環境に合わせて変更する。

- `PRIVATE_DIRECTORY_PATH`
    - クレデンシャルファイルやシーケンスファイル、ブックマークファイルを格納する「プライベートディレクトリ」のパス。Ruby の配置先から見た相対パスで記載できる
    - ex. Apache サーバの `/var/www/html/` に `index.rb` を配置した場合、`'../private'` と指定すれば、`/var/www/private/` ディレクトリ配下を参照するようになる
- `CREDENTIAL_FILE_PATH`
    - アクセスパスワードを書いた「クレデンシャルファイル」の名前を記す
    - `PRIVATE_DIRECTORY_PATH` と結合して参照するので、デフォルトの記述のままでいけば `/var/www/private/credential.txt` を参照することになる
- `SEQUENCE_FILE_PATH`
    - ブックマークのシーケンス値を管理する「シーケンスファイル」の名前を記す
    - `PRIVATE_DIRECTORY_PATH` と結合するので、デフォルトの記述のままでいけば `/var/www/private/bookmarks-sequence.txt` といったファイルが生成される
    - ファイルが存在しなかった場合は `0` を記入したファイルを生成する
- `BOOKMARKS_FILE_PATH`
    - ブックマーク一覧を保存する「ブックマークファイル」の名前を記す
    - `PRIVATE_DIRECTORY_PATH` と結合するので、デフォルトの記述のままでいけば `/var/www/private/bookmarks.txt` といったファイルが生成される
    - ファイルが存在しなかった場合は空ファイルを生成する
- `PAGE_TITLE`
    - `title` 要素、および `h1` 要素で示されるページタイトル


## 導入方法

1. Apache サーバで Ruby を CGI として利用できるように設定する
2. Apache サーバの `/var/www/html/` 配下などに `index.rb` を配置する
3. 変数 `PRIVATE_DIRECTORY_PATH` + `CREDENTIAL_FILE_PATH` のパスに、アクセスパスワードを記した1行のテキストファイル (クレデンシャルファイル) を作る
4. `index.rb`、プライベートディレクトリ、クレデンシャルファイル、シーケンスファイル、ブックマークファイルのパーミッションを適宜設定する
5. `index.rb` にアクセスする


## 管理者閲覧の方法

URL に `credential` パラメータを指定してアクセスすると、ブックマーク一覧が表示できる。

- ex. `http://example.com/index.rb?credential=MY_CREDENTIAL`

`credential` パラメータで指定したパスワードの整合性は、「クレデンシャルファイル」と突合して確認する。

管理者用画面では、新規ブックマークの追加と、ブックマーク一覧の表示、ブックマークの削除が行える。


## ブックマークレットでブックマークを追加する

次のようなブックマークレットを用意することで、閲覧中のページを新規ブックマークとして追加できるようになる。

```javascript
javascript:(()=>{window.open('http://example.com/index.rb?credential=MY_CREDENTIAL&mode=add&title='+encodeURIComponent(document.title)+'&url='+encodeURIComponent(document.URL))})();

javascript:(()=>{location.href='http://example.com/index.rb?credential=MY_CREDENTIAL&mode=add&title='+encodeURIComponent(document.title)+'&url='+encodeURIComponent(document.URL)})();
```


## Links

- [Neo's World](https://neos21.net/)
