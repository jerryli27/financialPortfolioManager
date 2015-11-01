-- The database for EECS 339 project 2 is set up by running the sql commands in this file 
-- The database is not set up by directly running this file
-- Instead, the commands was entered and executed one by one manually
-- This is the reference for any question related to database design for project 2


create table portfolio_users
  (user_name varchar(64) not null,
  password varchar(64) not null,
  primary key (user_name)
  );

create table portfolio_portfolio
  (portfolio_name varchar(64) not null,
  user_name varchar(64) not null,
  cash number default 0,
  foreign key (user_name) references portfolio_users(user_name),
  unique (portfolio_name,user_name)
  );

create table portfolio_stocks
  (symbol varchar(16) not null,
  timestamp number not null,
  open number not null,
  high number not null,
  low number not null,
  close number not null,
  volume number not null,
  PRIMARY KEY (symbol,timestamp)
  );

create table portfolio_stock_symbols
  (symbol varchar(64) not null)
  primary key (symbol));

-- this sequence is for transaction_id in portfolio_transactions
create sequence seq_transaction_id
  minvalue 1
  start with 1
  increment by 1
  cache 10;

-- when inserting into portfolio_transactions, transaction_id value has to be seq_transaction_id.nextval
create table portfolio_transactions
  (transaction_id int not null,
  portfolio_name varchar(64) not null,
  user_name varchar(64) not null,
  symbol varchar(16) not null,
  price number not null,
  amount number not null,
  timestamp number not null,
  method varchar(1) not null,
  primary key (transaction_id),
  foreign key (portfolio_name,user_name) references portfolio_portfolio(portfolio_name,user_name),
  foreign key (symbol) references portfolio_stock_symbols(symbol)
  );
