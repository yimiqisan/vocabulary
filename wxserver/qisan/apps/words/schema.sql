/*DROP TABLE IF EXISTS words;*/
CREATE TABLE IF NOT EXISTS words (
  id integer PRIMARY KEY AUTOINCREMENT,
  word varchar(255) NOT NULL UNIQUE,
  meaning string NOT NULL
);