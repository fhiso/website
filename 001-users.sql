DROP TABLE IF EXISTS group_membership;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS groups;

CREATE TABLE users (
    id                  INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    
    name                TEXT NOT NULL,
    email_address       TEXT NOT NULL,
    password_crypt      TEXT NOT NULL,

    date_registered     DATETIME NOT NULL,
    date_verified       DATETIME,
    date_approved       DATETIME,

    approved_by         INTEGER UNSIGNED,

    activation_token    TEXT,
    new_email_address   TEXT,

    FOREIGN KEY (approved_by) REFERENCES users(id)

) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;


-- Permission groups of users, e.g. for the TSC, various EGs, etc.
CREATE TABLE groups (
    id                  INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

    code                VARCHAR(16) NOT NULL,  -- name used in the code base
    name                TEXT NOT NULL  -- human readable name
) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

CREATE TABLE group_membership (
    user_id             INTEGER UNSIGNED NOT NULL,
    group_id            INTEGER UNSIGNED NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (group_id) REFERENCES groups(id),
    UNIQUE INDEX (user_id, group_id)
);

INSERT INTO groups (code, name) VALUES 
  ('tsc', 'Technical Standing Committee');
