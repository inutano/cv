---
name: update-cv
description: Use when adding or updating entries in this CV repository - syncing the publication list with ORCID, or adding a talk, invited lecture, book chapter, review article, seminar, grant, or committee role that was given as free-form text (学会発表・招待講演・著書・総説・講習会・獲得予算を追加したい、論文を ORCID から取り込みたい).
---

# CV の更新

## 前提

CV は日英2ファイルあり、**論文・プレプリント節は両ファイルで完全に同一**でなければならない。

| path | 役割 |
|---|---|
| `docs/cv.md` | 日本語版。全セクションを持つ |
| `docs/cv_en.md` | 英語版。総説・口頭発表・学会活動・講習会の節は無い |
| `data/publications_doi.txt` | 査読付き論文の DOI。新しい順 |
| `data/preprints_doi.txt` | プレプリントの DOI。新しい順 |
| `data/excluded_doi.txt` | ORCID にあるが CV の論文・プレプリント節には載せない DOI。理由を `#` で併記 |
| `bin/orcid_sync.sh` | ORCID と `data/*_doi.txt` の差分を表示する（読み取り専用） |
| `bin/resolve_doi.sh` | DOI リストを Markdown の引用行に変換する |
| `bin/check_cv.sh` | 重複・日英のずれ・DOI リストと本文の食い違いを検査する |
| `bin/make_nophoto.sh` | 顔写真なし版 `docs/cv_nophoto.md` / `docs/cv_en_nophoto.md` を生成する。生成物は git 管理外で、PDF ビルド時に自動生成される。手で編集しない |

作業の最後は必ず `sh bin/check_cv.sh` が `0 problem(s)` で終わること。

## モードA: ORCID から論文を取り込む

1. `sh bin/orcid_sync.sh` を実行する。`## unclassified` に出た DOI が未処理分。
2. 各 DOI を ORCID の type で振り分ける。
   - `journal-article`, `conference-paper` → `data/publications_doi.txt`
   - `preprint`、および bioRxiv / BioHackrXiv / arXiv なのに `other` と記録されているもの → `data/preprints_doi.txt`
   - `book-chapter` など、すでに著書節などに手で書いてあるもの → `data/excluded_doi.txt` に理由付きで
   - **判断に迷うものはユーザーに確認する。勝手に決めない。**
3. DOI リストの**発行日の新しい順**の位置に挿入する。同一年内は月日まで見て並べる。
4. **追加した DOI だけ**を一時ファイルに書き、`sh bin/resolve_doi.sh <一時ファイル>` で引用行を得る。
5. 得られた行を `docs/cv.md` と `docs/cv_en.md` の対応する節の同じ位置に挿入する。
6. `sh bin/check_cv.sh` を実行する。
7. `## no DOI in ORCID` に出た項目は自動処理できない。一覧をユーザーに報告して判断を仰ぐ。

### リスト全体を再生成しないこと

既存行には DOI メタデータ側の誤りを手で直した箇所がある。全件再生成すると壊れる。

| 場所 | 手で直してある内容 |
|---|---|
| `10.1038/nbt.3758` | `**Robotic Biology Consortium**` を著者として太字にしてある |
| `10.37044/osf.io/8qdse` | Crossref が `dumontier m` と小文字で持っているのを `Dumontier M` に直してある |
| `10.1101/165522` | bioRxiv 側のタイトルが `Cerasus ×- yedoensis` なのを `Cerasus × yedoensis` に直してある |

どうしても全件再生成する場合は、この表の修正を当て直してから `bin/check_cv.sh` を通す。

## モードB: ORCID に無い項目を手で追加する

ユーザーが発表や著書の情報を文章で渡してくる。**不足している情報（日付・ISBN・共著者・会議の正式名称）は推測せず質問する。**

節ごとの書式。いずれも**新しいものが上**、自分の名前は太字（`**Ohta T**` / `**大田達郎**`）。

| 節 (cv.md) | 節 (cv_en.md) | 書式 |
|---|---|---|
| `## 総説` | なし | `1. **大田達郎**. 「タイトル」 媒体名 号 (YYYY/MM/DD) URL` |
| `## 著書` | `## Book` | 英語: `1. **Ohta T**, 共著者. Title. Book Title. Published online YYYY:頁. doi:..., ISBN: ...` / 日本語: `1. **大田達郎**, 共著者. 「タイトル」 編者/編, 書名 (YYYY/MM/DD) ISBN ...` |
| `## 学会/研究会 口頭発表` | なし | `1. **Tazro Ohta**, 共著者. "Title", 会議の正式名称 (YYYY/MM/DD)` |
| `## 招待講演` | `## Invited Talk` | `1. "Title", 会議名 (YYYY/MM/DD)` |
| `## 学会活動・社会活動` | なし | `1. 役職を含む記述 (YYYY-)` |
| `## 講習会` | なし | `1. 「タイトル」 講習会名 (AJACSxx), (YYYY/MM/DD)` |
| `## 獲得予算` | `## Funding` | `1. 大田達郎 (研究代表者\|研究分担者) 「課題名」制度名 課題番号 (YYYY-YYYY)` |

### 両ファイルに入れる節の扱い

`## 著書` / `## Book`、`## 招待講演` / `## Invited Talk`、`## 獲得予算` / `## Funding` は日英両方に追記する。
既存の運用では、日本語の書籍・講演・予算は**英語版でも日本語表記のまま**載っている。英訳を勝手に作らない。英題があるものだけ英語で書く。

## よくある失敗

| 失敗 | 対処 |
|---|---|
| 片方のファイルにだけ追加した | `bin/check_cv.sh` が検出する。必ず最後に走らせる |
| 論文リストを全件再生成して手修正を消した | 上の「リスト全体を再生成しないこと」を読む |
| 同じ論文を2回追加した | `bin/check_cv.sh` が検出する |
| DOI リストに足したが本文に反映し忘れた | `bin/check_cv.sh` が検出する |
| 日付が不明なまま「2025」等と概算で書いた | 推測しない。ユーザーに聞く |
