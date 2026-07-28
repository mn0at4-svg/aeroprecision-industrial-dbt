# 製造業RFQ見積自動化におけるAIガードレール

[English](https://mn0at4-svg.github.io/aeroprecision-industrial-dbt/rfq-ai-guardrails/) | [日本語](https://mn0at4-svg.github.io/aeroprecision-industrial-dbt/rfq-ai-guardrails-ja/)

> 決定論的な財務コントロールとHuman Approvalを正本に残し、LLMを上限付き・観測可能・fail-closedな説明補助として設計しました。

## エグゼクティブサマリー

製造業のRFQ見積には、原価、粗利率、納期、顧客との信頼に影響する判断が含まれます。LLMは説明や情報整理を速くできますが、原価計算や承認の権限を持つべきではありません。

このケーススタディは、合成製造データを用いた **AeroPrecision Industrial** を題材に、テスト可能なデータ基盤、決定論的な見積コントロール、上限付きのLLM補助、可観測性、Human Approval境界を統合した設計を示します。

設計原則は明確です。

> AIには説明と補助を任せる。財務上の権限は、決定論的なコントロールと説明責任を持つ人間に残す。

## 業務上のリスク

言語モデルが原価、粗利率、価格、承認に影響または上書きを行える状態では、見積フローは安全ではありません。

そのため、本ワークフローでは責任を3つに分離しています。

| 責任領域 | 正本となる権限 | 設計意図 |
|---|---|---|
| 原価、粗利率、最低価格、適合判定 | 決定論的な計算ロジック | 再現可能・テスト可能・監査可能 |
| 説明、根拠、交渉支援 | 上限付きLLM | 有用だが、意思決定の正本にはしない |
| 保存、通知、外部操作、最終承認 | Human Approval | 説明責任を持つ業務コントロール |

## ワークフローの全体像

1. 合成L0/L1のRFQを、必須項目、許可値、重複処理、製品IDの観点で検証します。
2. BigQueryの製品マスタをread-onlyで参照します。
3. 決定論的ロジックにより、材料費、労務費、総原価、CFO最低価格、実現粗利率を計算します。
4. LLMには許可済みL0/L1だけを渡し、見積説明や交渉根拠の補助をさせます。計算や承認はさせません。
5. AI出力を構造的に検証し、呼び出しは最大3回に制限します。
6. timeout、構造不正、検証失敗、上限到達時はfail-closedで停止します。
7. Human Approvalの前に保存、通知、外部送信は行いません。

## LLMに決定させないこと

| 判断 | 正本 | LLMの役割 |
|---|---|---|
| 材料費・労務費 | 決定論的コード | なし |
| CFO最低価格 | 決定論的コード | なし |
| 粗利率の適合判定 | 決定論的コード | なし |
| 承認・却下 | Human Approval | なし |
| 説明・交渉支援 | 検証済みAI出力 | 上限付き補助 |

この境界により、もっともらしいが未検証のモデル出力が、財務判断を上書きすることを防ぎます。

## 合成データによる制御試験の証跡

受入試験には合成L0/L1データだけを使い、計算・承認の境界を越えずに上限付きループが動くことを確認しました。

| ケース | LLM呼び出し | Prompt tokens | Output tokens | 処理時間 | 結果 |
|---|---:|---:|---:|---:|---|
| 初回成功 | 1 | 412 | 167 | 7,144 ms | 説明出力を検証 |
| リトライ後に回復 | 2 | 887 | 261 | 9,876 ms | 1回目を棄却し、2回目を検証 |
| fail-closed | 3 | 1,369 | 357 | 12,025 ms | 4回目は呼ばず、承認・保存・外部操作へ進まない |

重要なのは、AI呼び出しが常に成功することではありません。失敗または信頼できない出力が、財務コントロールやHuman Approval境界を緩めないことです。

## unsafeな内容を保持しない可観測性

n8nからlocal self-hosted Langfuseへ、OTLP HTTPで匿名化した運用メタデータを送信します。raw promptやraw LLM outputは保存しません。

追跡する主な情報は以下です。

- business trace IDと派生OpenTelemetry trace ID
- workflow execution ID
- モデル、プロバイダー、attempt数、最大attempt数
- input/output hash
- token数、latency、cost
- validation結果、retry判断、停止理由
- fail-closed理由
- Human Approvalとpersistenceの状態

これにより、機微なAI入出力を可観測性データとして保持せずに、LLM層の動作をレビューできます。

## 設計・実装したこと

- dbtとBigQueryによる、再構築可能でテスト可能なデータ基盤
- 財務コントロールと整合する決定論的なRFQ計算契約
- 入力検証、idempotency、上限付きリトライ、Human Approvalを備えた安全なn8nオーケストレーション
- LLMを説明補助に限定する入出力契約
- timeout、構造不正、検証失敗、上限到達時に安全停止するfail-closed経路
- rawコンテンツではなく匿名化メタデータを追跡するLangfuse可観測性
- 技術・業務双方の関係者がレビューできる設計書、合成テスト計画、証跡

## 他社環境へ応用できる価値

本プロジェクトは、製造オペレーション、財務コントロール、データ基盤、AI自動化を安全につなぐための設計です。

価値は、AIが人間の意思決定を置き換えるという主張ではありません。どの判断を決定論的に残すべきか、どの業務をAIで安全に補助できるか、そしてワークフロー全体をどう観測・監査できるかを設計することにあります。

## 技術証跡

- [Phase 2のスコープと判断](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase2/01_scope_and_decisions.md)
- [決定論的な計算仕様](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase2/02_deterministic_calculation_spec.md)
- [Human Approvalと監査仕様](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase2/03_human_approval_and_audit_spec.md)
- [上限付きループの設計](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase2/08_bounded_loop_engineering_design.md)
- [Phase 2デモの証跡](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase2/11_phase2_n8n_demo_evidence.md)
- [Langfuse可観測性の設計](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase3/01_langfuse_observability_design.md)
- [ローカル統合証跡](https://github.com/mn0at4-svg/aeroprecision-industrial-dbt/blob/main/docs/phase3/04_local_integration_evidence.md)

[既存の運用ダッシュボードへ戻る](https://mn0at4-svg.github.io/aeroprecision-industrial-dbt/)
