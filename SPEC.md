# SPEC.md (Project Specification)

このファイルは「工種」「工程」「DB構造」の公式仕様書です。  
Codex は作業するとき、必ずこの SPEC.md の内容を守ること。

---

## 1. 工種 (member_type)

- 柱
- 大梁
- 小梁
- 間柱
- 胴縁
- 母屋
- 他

---

## 2. 工程の階層構造

### process_groups（上位工程）
- 一次加工
- コア部
- 仕口部
- 大組部
- 二次部材
- 製品検査
- 製品塗装
- 積込
- 出荷

### process_steps（下位工程）
- 切断
- 孔あけ
- 開先加工
- ショットブラスト
- 罫書
- 組立
- 溶接
- UT
- 寸法検査
- 塗装

※ 現時点では **グループ単位の進捗管理のみ使用する**  
※ 将来、process_steps を細かく使うことができる（設計済）

---

## 3. DB設計（必ずこの構造を守る）

### process_groups
- id
- key (英語)
- label (日本語)
- sort_order

### process_steps
- id
- group_id
- key (英語)
- label (日本語)
- sort_order

### process_progress_daily
- id
- product_id
- step_id
- date
- done_qty
- note

---

## 4. 進捗管理ルール

- 進捗は「日付＋工程（step_id）ごとの完了台数」を登録する
- 製品台数と比較して「進捗率」を算出する
- 未来日への入力は不可（仕様）
- 既存データの過去修正は可能

---

## 5. Codex への重要指示

- Codex は SPEC.md の内容を絶対に変更しないこと
- Codex はここに書かれた仕様に従ってコード生成すること
- SPEC.md に存在しない工程名・DB項目を勝手に作らないこと
