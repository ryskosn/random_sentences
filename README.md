## これはなに 

[こういうスプレッドシート](https://docs.google.com/spreadsheets/d/e/2PACX-1vSYbshWQnW153OnUoMb9cCtShDiwExQQKvfNCe31B5mcAcW1wOnbqO9WANSH_hw0j6JHXJfd-hebfNL/pubhtml#)に入力した文章をランダムに表示する仕組み。

外国人の方に日本語を教える仕事をしている知人から、授業の中で例文をランダムに表示したいという相談を受けて作ってみた。

- [動作サンプル](https://hardcore-franklin-9b84b0.netlify.com)

### 使用方法

1. `fetch` ボタンをクリックする
2. ドロップダウンリストからカテゴリーを選択する
3. `Pick` ボタンをクリックするとランダムに文章を表示する
4. `note` ボタンで note の表示・非表示を切り替えられる


### スプレッドシートのデータを JSON で取得する API を用意する

下記記事を参考にした。

- [Google SpreadSheet のデータを JSON 形式で取得する Web API をサクッと作る - Qiita](https://qiita.com/takatama/items/7aa1097aac453fff1d53)
- [Class SpreadsheetApp  |  Apps Script  |  Google Developers](https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet-app)
- [Array.prototype.splice() - JavaScript | MDN](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/splice)

下記 URL にアクセスするとシートの内容の JSON が表示される。

- https://script.google.com/macros/s/AKfycbzlrM98-jzVRi3hTwH7OGpal6KTNBxoZX659zMqkF2U6QH1Ee8/exec


### build & deploy

```sh
$ elm make src/Main.elm --output dest/elm.js
```

```sh
$ netlify deploy --dir=dest/
$ netlify deploy --prod
```

