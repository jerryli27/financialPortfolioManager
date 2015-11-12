Northwestern 2015 Fall EECS 339 Project 2: Portfolio Management
Team members: Jiaming Li (jlt709), Alan Fu (yfo776)

Application website: http://murphy.wot.eecs.northwestern.edu/~yfo776/portfolio/test.pl

Application design: Project 2 mockup.pdf
ER diagram: ER Diagram.pdf
Relational design: this is reflected in portfolio.sql
SQL DDL: portfolio_sql
Main CGI script: test.pl

The following parts are also implemented for extra-credits --

## 1. Automatic Stock Updates
* Implemented getting all the available historical data from yahoo finance
* The data is stored in the portfolio_stocks table in the database
* A cron job has been set up for automatic updates each day

## 2. Additional Statistics
In addition to stddev, beta and covariance, we have implemented the following additional statistics, which can all be viewed in the statistics tab:
* 200-day moving average -- average closing price of the latest 200 trading days
* 200-day high -- highest closing price of the latest 200 trading days
* 200-day low -- lowest closing price of the latest 200 trading days
* 200-day average volume -- average trading volume of the latest 200 trading days

