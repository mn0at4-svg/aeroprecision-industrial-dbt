---
title: CFO Executive Dashboard
---

<div class="rounded-2xl border border-primary/30 bg-gradient-to-br from-primary/20 via-base to-accent/10 p-8 shadow-lg">

<div class="mb-5 flex flex-wrap gap-2">

<span class="rounded-full border border-primary/30 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
CFO Decision Intelligence
</span>

<span class="rounded-full border border-positive/30 bg-positive/10 px-3 py-1 text-xs font-semibold text-positive">
BigQuery + dbt
</span>

<span class="rounded-full border border-accent/30 bg-accent/10 px-3 py-1 text-xs font-semibold text-accent">
12-Month RFQ View
</span>

</div>

<p class="mb-2 text-sm font-semibold uppercase tracking-widest text-primary">
AeroPrecision Industrial
</p>

<h2 class="mb-2 text-3xl font-bold tracking-tight">
Quotation Speed, Win Rate & Margin Governance
</h2>

<h3 class="mb-5 text-xl font-semibold opacity-90">
見積スピード・受注率・マージンガバナンス
</h3>

<p class="mb-2 text-base leading-7 opacity-80">
Monitor quotation speed, win rate, and compliance with the CFO margin policy.
</p>

<p class="text-base leading-7 opacity-80">
見積回答スピード、受注率、CFOマージンルールの遵守状況を経営視点で監視します。
</p>

</div>

<div class="h-8"></div>


```sql cfo_alerts
select
    count(*) filter (
        where calculated_is_margin_violated
          and is_won
    ) as won_bad_deals,
    sum(revenue_leak_usd) as revenue_leak_usd,
    count(*) filter (
        where quote_method = 'AI-Automated'
          and is_won
    ) * 1.0 / nullif(
        count(*) filter (
            where quote_method = 'AI-Automated'
        ),
        0
    ) as ai_win_rate,
    count(*) filter (
        where quote_method = 'Manual'
          and is_won
    ) * 1.0 / nullif(
        count(*) filter (
            where quote_method = 'Manual'
        ),
        0
    ) as manual_win_rate
from aeroprecision.quotation_performance
```

<Alert status="warning">

**Margin Exception Exposure / マージン例外リスク**

<Value data={cfo_alerts} column=won_bad_deals/> won deals were priced below the CFO-approved margin threshold, generating <Value data={cfo_alerts} column=revenue_leak_usd fmt=usd0/> in potential revenue leakage.

CFO承認マージンを下回る受注案件が<Value data={cfo_alerts} column=won_bad_deals/>件あり、<Value data={cfo_alerts} column=revenue_leak_usd fmt=usd0/>の収益漏洩が発生しています。

</Alert>

<Alert status="positive">

**AI Automation Opportunity / AI自動化による機会**

AI-automated quotations achieved a <Value data={cfo_alerts} column=ai_win_rate fmt=pct0/> win rate, compared with <Value data={cfo_alerts} column=manual_win_rate fmt=pct0/> for manual quotations.

AI自動見積の受注率は<Value data={cfo_alerts} column=ai_win_rate fmt=pct0/>で、手動見積の<Value data={cfo_alerts} column=manual_win_rate fmt=pct0/>を大幅に上回っています。

</Alert>

```sql executive_kpis
select
    count(*) as total_quotes,
    count(*) filter (where is_won) as won_quotes,
    count(*) filter (where not is_won) as lost_quotes,
    count(*) filter (
        where quote_method = 'AI-Automated'
    ) as ai_quotes,
    count(*) filter (
        where calculated_is_margin_violated
    ) as margin_violation_quotes,
    count(*) filter (
        where calculated_is_margin_violated
          and is_won
    ) as won_margin_violation_deals,
    count(*) filter (where is_won) * 1.0
        / nullif(count(*), 0) as overall_win_rate,
    1 - (
        count(*) filter (
            where calculated_is_margin_violated
        ) * 1.0 / nullif(count(*), 0)
    ) as margin_compliance_rate,
    avg(quote_lead_time_days) as avg_quote_lead_time_days,
    sum(
        case
            when is_won then quoted_price_usd
            else 0
        end
    ) as won_revenue_usd,
    sum(
        case
            when is_won
                then quoted_price_usd - estimated_total_cost_usd
            else 0
        end
    ) as won_gross_profit_usd,
    sum(revenue_leak_usd) as revenue_leak_usd
from aeroprecision.quotation_performance
```

## Executive KPIs

### 経営主要指標

<Grid cols=3 gapSize=lg>

<div class="h-full rounded-xl border border-info/30 bg-info/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=total_quotes
    title="Total Quotes / 見積総数"
/>

</div>

<div class="h-full rounded-xl border border-positive/30 bg-positive/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=overall_win_rate
    title="Overall Win Rate / 全体受注率"
    fmt=pct1
/>

</div>

<div class="h-full rounded-xl border border-primary/30 bg-primary/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=avg_quote_lead_time_days
    title="Average Quote Lead Time (Days) / 平均見積回答日数"
    fmt="0.0"
/>

</div>

</Grid>

<div class="h-6"></div>

<Grid cols=3 gapSize=lg>

<div class="h-full rounded-xl border border-info/30 bg-info/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=won_revenue_usd
    title="Won Revenue / 受注売上"
    fmt=usd0
/>

</div>

<div class="h-full rounded-xl border border-positive/30 bg-positive/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=won_gross_profit_usd
    title="Won Gross Profit / 受注粗利益"
    fmt=usd0
/>

</div>

<div class="h-full rounded-xl border border-negative/30 bg-negative/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=revenue_leak_usd
    title="Revenue Leakage / 収益漏洩"
    fmt=usd0
/>

</div>

</Grid>

<div class="h-10"></div>

## Margin Governance

### マージンガバナンス

<Grid cols=3 gapSize=lg>

<div class="h-full rounded-xl border border-positive/30 bg-positive/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=margin_compliance_rate
    title="Margin Compliance Rate / マージン遵守率"
    fmt=pct1
/>

</div>

<div class="h-full rounded-xl border border-warning/30 bg-warning/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=margin_violation_quotes
    title="Margin Violations / マージン違反"
/>

</div>

<div class="h-full rounded-xl border border-negative/30 bg-negative/10 p-5 shadow-sm">

<BigValue
    data={executive_kpis}
    value=won_margin_violation_deals
    title="Won Bad Deals / 違反受注案件"
/>

</div>

</Grid>


## AI Automation Impact

### AI自動化による効果

Compare AI-automated and manual quotation win rates to evaluate the business impact of response speed.

AI自動見積と手動見積の受注率を比較し、回答スピードが商談成果に与える影響を確認します。

```sql method_performance
select
    quote_method,
    count(*) as total_quotes,
    count(*) filter (where is_won) as won_quotes,
    count(*) filter (where not is_won) as lost_quotes,
    count(*) filter (where is_won) * 1.0
        / nullif(count(*), 0) as win_rate,
    avg(quote_lead_time_days) as avg_quote_lead_time_days,
    sum(
        case
            when is_won then quoted_price_usd
            else 0
        end
    ) as won_revenue_usd
from aeroprecision.quotation_performance
group by quote_method
order by win_rate desc
```

<BarChart
    data={method_performance}
    x=quote_method
    y=win_rate
    yFmt=pct0
    labels=true
    yMin=0
    yMax=0.8
    title="Win Rate by Quotation Method / 見積方式別受注率"
    subtitle="Immediate AI response versus 1.5–6.0 day manual response / AI即時回答と手動回答の比較"
/>

## Response Speed Impact

### 見積回答スピードによる影響

Evaluate how quotation response time affects the probability of winning an RFQ.

見積回答時間がRFQの受注確率に与える影響を確認します。

```sql speed_performance
select
    response_speed_band,
    count(*) as total_quotes,
    count(*) filter (where is_won) as won_quotes,
    count(*) filter (where is_won) * 1.0
        / nullif(count(*), 0) as win_rate,
    avg(quote_lead_time_days) as avg_quote_lead_time_days,
    case
        when avg(quote_lead_time_days) = 0 then 1
        when avg(quote_lead_time_days) <= 3 then 2
        else 3
    end as speed_order
from aeroprecision.quotation_performance
group by response_speed_band
order by speed_order
```

<BarChart
    data={speed_performance}
    x=response_speed_band
    y=win_rate
    yFmt=pct0
    labels=true
    yMin=0
    yMax=0.8
    sort=false
    title="Win Rate by Response Speed / 回答スピード別受注率"
    subtitle="Faster quotation responses produce materially higher win rates / 回答の高速化が受注率を大幅に改善"
/>

## Category Margin Risk

### 製品カテゴリ別マージンリスク

Identify product categories generating margin violations and realized revenue leakage.

マージン違反と実現した収益漏洩が集中している製品カテゴリを特定します。

```sql category_margin_risk
select
    category,
    count(*) as total_quotes,
    count(*) filter (
        where calculated_is_margin_violated
    ) as margin_violation_quotes,
    count(*) filter (
        where calculated_is_margin_violated
          and is_won
    ) as won_margin_violation_deals,
    sum(revenue_leak_usd) as revenue_leak_usd,
    sum(
        case
            when is_won then quoted_price_usd
            else 0
        end
    ) as won_revenue_usd
from aeroprecision.quotation_performance
group by category
order by revenue_leak_usd desc
```

<Grid cols=1>

<BarChart
    data={category_margin_risk}
    x=category
    y=revenue_leak_usd
    yFmt=usd0
    labels=true
    swapXY=true
    sort=true
    title="Revenue Leakage by Category / カテゴリ別収益漏洩"
    subtitle="Leakage from won quotes below the CFO margin threshold / CFO基準未満で受注した案件の収益漏洩"
/>

<BarChart
    data={category_margin_risk}
    x=category
    y=margin_violation_quotes
    labels=true
    swapXY=true
    sort=true
    title="Margin Violations by Category / カテゴリ別マージン違反"
    subtitle="All quotes priced below the target gross margin / 目標粗利率を下回った全見積"
/>

</Grid>


## Revenue Leakage Deals

### 収益漏洩が発生した受注案件

Review won quotations that were priced below the CFO-approved gross margin threshold.

CFO承認粗利率を下回る価格で受注した案件を確認します。

```sql revenue_leakage_deals
select
    quote_id,
    quote_date,
    customer_name,
    category,
    quote_method,
    quoted_price_usd,
    actual_gross_margin_pct,
    cfo_target_gross_margin_pct,
    revenue_leak_usd
from aeroprecision.quotation_performance
where calculated_is_margin_violated
  and is_won
order by revenue_leak_usd desc
```

<DataTable
    data={revenue_leakage_deals}
    rows=all
    search=true
    rowShading=true
>
    <Column id=quote_id title="Quote ID / 見積ID"/>
    <Column id=quote_date title="Date / 見積日"/>
    <Column id=customer_name title="Customer / 顧客"/>
    <Column id=category title="Category / カテゴリ"/>
    <Column id=quote_method title="Method / 方式"/>
    <Column
        id=quoted_price_usd
        title="Quoted Price / 見積額"
        fmt=usd0
    />
    <Column
        id=actual_gross_margin_pct
        title="Actual GM / 実粗利率"
        fmt=pct1
    />
    <Column
        id=cfo_target_gross_margin_pct
        title="Target GM / 目標粗利率"
        fmt=pct1
    />
    <Column
        id=revenue_leak_usd
        title="Leakage / 漏洩額"
        fmt=usd0
    />
</DataTable>


## Monthly Performance Trend

### 月別パフォーマンストレンド

Track monthly win-rate changes and the performance difference between AI-automated and manual quotations.

月別の受注率推移と、AI自動見積・手動見積の成果差を確認します。

```sql monthly_method_trend
select
    quote_month,
    quote_method,
    count(*) as total_quotes,
    count(*) filter (where is_won) as won_quotes,
    count(*) filter (where is_won) * 1.0
        / nullif(count(*), 0) as win_rate,
    avg(quote_lead_time_days) as avg_quote_lead_time_days
from aeroprecision.quotation_performance
group by
    quote_month,
    quote_method
order by
    quote_month,
    quote_method
```

<LineChart
    data={monthly_method_trend}
    x=quote_month
    y=win_rate
    series=quote_method
    yFmt=pct0
    yMin=0
    yMax=1
    markers=true
    title="Monthly Win Rate by Quotation Method / 見積方式別月次受注率"
    subtitle="Trend comparison across the 12-month RFQ history / 過去12か月のRFQ受注率推移"
/>