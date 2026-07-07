# OpenClaw Equity Research Framework

## Source Patterns
This skill borrows two architecture patterns:

1. OpenBB-style platform base:
   - Treat market data, fundamentals, filings, news, and analyst data as provider modules.
   - Produce artifacts that can feed a terminal, workspace, dashboard, MCP server, or agent.
   - Keep data collection separate from synthesis.

2. Agentic stock research workflow:
   - Stock finder or triage agent identifies why a ticker matters.
   - Market data agent gathers price, volume, trend, technicals.
   - News analyst agent gathers catalysts, sentiment, calendar events.
   - Recommendation/synthesis agent turns evidence into a research view with risks.

## Stage Contract
Each stage should return facts plus interpretation, not free-form unsupported opinion.

### 1. Triage
Answer:
- Why is this ticker being researched now?
- Is it liquid enough for the user's likely use case?
- What is the main controversy or variant perception?

### 2. Market Data
Minimum:
- latest close or current price with timestamp
- 1 day, 1 month, 3 month, and 6 month return when available
- volume vs recent average
- 20/50/200 day moving averages
- RSI or momentum regime
- obvious support/resistance if a trading note is requested

### 3. Business/Fundamentals
Minimum:
- business description
- segment or revenue drivers when available
- market cap and enterprise value if available
- revenue growth, margins, cash generation, balance sheet risk when available
- peer group if the user asks for valuation

### 4. News/Catalysts
Minimum:
- recent headlines with dates
- earnings date or known event calendar when available
- product/regulatory/macro catalysts
- classify each as positive, negative, neutral, or uncertain

### 5. Valuation Frame
Use one or more:
- multiples: P/E, EV/Sales, EV/EBITDA, P/S, FCF yield
- scenario: base, bull, bear assumptions
- sum-of-the-parts for multi-segment companies
- DCF only when assumptions are explicit

Never give a precise target without showing assumptions.

### 6. Synthesis
Use:
- `Research View: Bullish`, `Neutral`, or `Bearish`
- `Confidence: Low`, `Medium`, or `High`
- `Time Horizon`
- monitoring checklist
- falsification triggers

Avoid personalized language like "you should buy." Prefer "A bullish case depends on..." or "The evidence supports a neutral research view until..."

## Quality Bar
A useful memo should:
- make the thesis clear in the first 10 lines
- include evidence that could change the conclusion
- separate near-term trading setup from long-term investment quality
- name data limitations
- be concise enough for a portfolio manager to scan
