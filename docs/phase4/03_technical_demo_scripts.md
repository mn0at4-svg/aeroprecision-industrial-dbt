# Phase 4 Technical Demo Scripts

## Production rules

- Duration target: 3–4 minutes. The scripts below target approximately 3 minutes 40 seconds.
- Create separate English and Japanese recordings. Do not mix narration languages.
- Use a local recording only. No upload, hosting, or LinkedIn posting is included in this step.
- Use synthetic L0/L1 data only.
- Do not show raw prompts, raw outputs, credentials, API keys, `.env` files, URLs containing secrets, or real customer information.
- Demonstrate the design boundary and evidence; do not create a node-by-node tutorial.

## English version — target 3 minutes 40 seconds

| Time | Visual | Narration |
|---:|---|---|
| 0:00–0:20 | Case-study title and one-sentence thesis | This is AeroPrecision Industrial, a manufacturing RFQ automation portfolio. The central design choice is that financial controls and Human Approval remain authoritative while the LLM is bounded, observable, and fail-closed. |
| 0:20–0:50 | Authority Boundary diagram | The workflow starts with validated RFQ data and a read-only product master. Deterministic logic calculates cost, gross margin, and the CFO minimum price. Those values are never delegated to the model. |
| 0:50–1:25 | Redacted n8n workflow overview | n8n orchestrates the process around that boundary. The LLM receives only approved L0/L1 context and can produce an explanation or negotiation rationale. It cannot approve a quote, persist a result, or send an external message. |
| 1:25–1:55 | Deterministic output fields or case-study control table | The output is checked against the deterministic contract. The model cannot override the calculation, change the CFO rule, or turn an invalid margin into an approved result. |
| 1:55–2:30 | Bounded Retry and Fail-Closed diagram with the three test outcomes | The AI response is validated on every attempt. In the synthetic acceptance tests, one case succeeded immediately, one recovered on the second attempt, and one stopped after three failed attempts. There is no fourth attempt. |
| 2:30–3:05 | Redacted Langfuse trace metadata | Langfuse makes the AI operations layer observable. I track attempts, token counts, latency, validation, retry decisions, hashes, and stop reasons. Raw prompts and raw outputs are not retained. |
| 3:05–3:30 | Human Approval boundary | The key operational control is here: before Human Approval, the workflow does not persist, notify, or send anything outside the workflow. A model failure cannot relax that boundary. |
| 3:30–3:40 | Closing card | This is how I connect manufacturing operations, data platforms, AI automation, and business governance without giving an LLM authority over high-risk decisions. |

## 日本語版 — 目標3分40秒

| 時間 | 映像 | ナレーション |
|---:|---|---|
| 0:00–0:20 | ケーススタディのタイトルと主張 | これは、製造業のRFQ見積を安全に支援するAeroPrecision Industrialのポートフォリオです。財務コントロールとHuman Approvalを正本に残し、LLMは上限付き・観測可能・fail-closedな補助に限定しています。 |
| 0:20–0:50 | 権限境界の図 | フローは、検証済みRFQとread-onlyの製品マスタから始まります。原価、粗利率、CFO最低価格は決定論的なロジックで計算し、モデルには委ねません。 |
| 0:50–1:25 | 匿名化したn8n全体フロー | n8nは、この権限境界を中心にオーケストレーションします。LLMに渡すのは許可済みのL0/L1だけです。説明や交渉根拠は補助できますが、承認、保存、外部送信はできません。 |
| 1:25–1:55 | 決定論的な出力項目または制御表 | 出力は決定論的な契約に対して再検証します。モデルが計算結果を書き換えたり、CFOルールを変えたり、不適切な粗利率を承認済みに変えたりすることはできません。 |
| 1:55–2:30 | リトライ上限とfail-closedの図、3ケースの結果 | AI出力は毎回検証します。合成データによる受入試験では、初回成功、2回目で回復、3回失敗で停止という3ケースを確認しました。4回目の呼び出しはありません。 |
| 2:30–3:05 | Langfuseの匿名化されたメタデータ | Langfuseでは、attempt、token数、処理時間、validation、retry判断、hash、停止理由を観測します。一方でraw promptとraw outputは保存しません。 |
| 3:05–3:30 | Human Approval境界 | 最も重要な運用上の制御はここです。Human Approvalの前に、保存、通知、外部送信は行いません。モデルが失敗しても、この境界が緩むことはありません。 |
| 3:30–3:40 | クロージングカード | 製造オペレーション、データ基盤、AI自動化、事業ガバナンスをつなぎつつ、高リスクな判断をLLMに委ねない設計です。 |
