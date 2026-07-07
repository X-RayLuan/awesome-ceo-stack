# Data Sources

## Preferred Source Order
Use the freshest reliable source available for the user's task.

### Market Data
- OpenBB Platform when installed and configured.
- yfinance for lightweight public price/profile/news data.
- Exchange or broker data if the user provides access.
- Web search for quotes only if API data is unavailable, and cite timestamp.

### Fundamentals
- SEC filings: 10-K, 10-Q, 8-K for US companies.
- Company investor relations: earnings releases, presentations, transcripts.
- OpenBB/yfinance public fundamentals for fast first pass.
- Paid sources only if the user has configured access.

### News And Catalysts
- Company press releases and IR calendar.
- Reputable financial news.
- Exchange filings and regulatory notices.
- Avoid unsourced social rumors unless the user asks for sentiment monitoring; label them as unverified.

### Estimates And Analyst Data
- Use only if sourced. Do not invent consensus estimates.
- If unavailable, write "not available in current data pull" and use scenario ranges instead.

## Provider Caveats
- yfinance fields can be incomplete, delayed, or inconsistent across tickers.
- OpenBB provider availability depends on local installation and provider credentials.
- News APIs may return headlines without full text.
- Current price data can be delayed; include timestamp.

## Browsing Rule
For current market price, news, legal/regulatory issues, earnings dates, analyst actions, or anything likely to have changed recently, browse or use an API unless the user explicitly says not to.

