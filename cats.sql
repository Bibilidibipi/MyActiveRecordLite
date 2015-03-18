CREATE TABLE cats (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  owner_id INTEGER,

  FOREIGN KEY(owner_id) REFERENCES humans(id)
);

CREATE TABLE humans (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL,
  house_id INTEGER,
  country_id INTEGER,

  FOREIGN KEY(house_id) REFERENCES houses(id),
  FOREIGN KEY(country_id) REFERENCES countries(id)
);

CREATE TABLE houses (
  id INTEGER PRIMARY KEY,
  address VARCHAR(255) NOT NULL
);

CREATE TABLE countries (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE trees (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  country_id INTEGER,

  FOREIGN KEY(country_id) REFERENCES countries(id)
);

INSERT INTO
  houses (id, address)
VALUES
  (1, "26th and Guerrero"), (2, "Dolores and Market");

INSERT INTO
  humans (id, fname, lname, house_id, country_id)
VALUES
  (1, "Devon", "Watts", 1, 1),
  (2, "Matt", "Rubens", 1, 2),
  (3, "Ned", "Ruggeri", 2, 1),
  (4, "Catless", "Human", NULL, 2);

INSERT INTO
  cats (id, name, owner_id)
VALUES
  (1, "Breakfast", 1),
  (2, "Earl", 2),
  (3, "Haskell", 3),
  (4, "Markov", 3),
  (5, "Stray Cat", NULL);

INSERT INTO
  countries (id, name)
VALUES
  (1, "France"),
  (2, "Germany");

INSERT INTO
  trees (id, name, country_id)
VALUES
  (1, "Eggbert", 1),
  (2, "Florian", 2),
  (3, "Visgoth", 1);
