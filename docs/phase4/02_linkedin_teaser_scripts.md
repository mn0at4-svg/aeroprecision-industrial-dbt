# Phase 4 LinkedIn Teaser Scripts

## Production rules

- Duration target: 45–60 seconds.
- Create separate English and Japanese videos. Do not mix narration languages.
- Reuse the same screen recording where appropriate; change only voice-over and subtitles.
- Record locally as an MP4. Do not commit MP4 files to Git.
- Use only synthetic L0/L1 data and redacted screens.
- Do not publish or upload this video until a separate approval is given.

## English version — target 55 seconds

| Time | Visual | Narration |
|---:|---|---|
| 0–5s | Title card: `Manufacturing RFQ Automation with AI Guardrails` | Manufacturing RFQ automation is not a place to let an LLM make financial decisions. |
| 5–15s | Authority Boundary diagram | I designed this workflow so cost, margin, minimum price, and approval remain deterministic and human-controlled. |
| 15–28s | High-level n8n workflow overview | The AI layer receives only approved context. Its role is to explain a validated quote, not calculate or approve it. |
| 28–40s | Bounded Retry and Fail-Closed diagram | Every response is validated. The workflow allows a maximum of three attempts, then fails closed without saving or sending anything. |
| 40–50s | Redacted Langfuse metadata screenshot | I made the AI layer observable with trace, token, latency, retry, and validation metadata—without retaining raw prompts or outputs. |
| 50–55s | Closing card: `Deterministic controls. Bounded AI. Human approval.` | The full case study is available in my GitHub portfolio. |

### English subtitle rules

- Use sentence-case subtitles with no more than two lines.
- Match the narration exactly; do not add claims that are not spoken.
- Keep terms consistent: deterministic, bounded, observable, fail-closed, Human Approval.
- Never display a raw prompt, raw output, credential, or local configuration value as a subtitle.

## 日本語版 — 目標55秒

| 時間 | 映像 | ナレーション |
|---:|---|---|
| 0–5秒 | タイトルカード | 製造業の見積自動化では、AIに財務判断を委ねるべきではありません。 |
| 5–15秒 | 権限境界の図 | 原価、粗利率、最低価格、承認は、決定論的なロジックと人間の管理下に残しています。 |
| 15–28秒 | n8nの全体フロー | AIに渡すのは許可した文脈だけです。AIの役割は、検証済み見積の説明であり、計算や承認ではありません。 |
| 28–40秒 | 上限付きリトライとfail-closedの図 | 出力は毎回検証し、呼び出しは最大3回までです。失敗時は保存も送信もせず、安全に停止します。 |
| 40–50秒 | Langfuseの匿名化されたメタデータ | trace、token、処理時間、retry、検証結果を観測できます。ただしraw promptとraw outputは保存しません。 |
| 50–55秒 | クロージングカード | 詳細はGitHubのケーススタディをご覧ください。 |

### 日本語字幕ルール

- 英語を混在させず、必要な技術語だけを表記します。
- 1画面は最大2行にします。
- ナレーションと字幕の主張を一致させます。
- 秘密情報、raw prompt、raw output、認証情報を字幕に含めません。
