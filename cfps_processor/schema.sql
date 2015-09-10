DROP TABLE IF EXISTS cfps_references;

-- Break the circular references between papers and cfps before we can drop.
ALTER TABLE cfps DROP FOREIGN KEY cfps_ibfk_2;
DROP TABLE IF EXISTS papers;
DROP TABLE IF EXISTS cfps;

DROP VIEW cfps_see_also;
DROP TABLE IF EXISTS cfps_types;

-- Note that the name is hard-coded into the code.
CREATE TABLE cfps_types (
    id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL
) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

INSERT INTO cfps_types (id, name, description) VALUES
    (1, 'Proposal', 'Technical proposal'),
    (2, 'Requirement', 'Functional requirements'),
    (3, 'Area to Standardise', 'An area requiring standardisation'),
    (4, 'Comment', 'A comment on a submitted paper'),
    (5, 'Update', 'An updated version of a previously submitted paper');

CREATE TABLE cfps (
    -- This is the main CFPS ID.
    id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

    -- Author details are constant across versions
    given_name      TEXT NOT NULL,
    surname         TEXT NOT NULL,
    email           TEXT NOT NULL,
    submission_type INTEGER UNSIGNED NOT NULL,
    date_created    DATE NOT NULL,

    -- The id of the latest version of the paper.
    -- This shouldn't really be needed, and it breaks normal form and 
    -- introduces circular dependencies on tables.  Unfortunately we cannot
    -- rely on papers.version_created being correctly-ordered because it's 
    -- only a DATE rather than a DATETIME, and version needs special parsing
    -- to order 1.9 < 1.10 correctly.
    latest_version  INTEGER UNSIGNED,

    FOREIGN KEY (submission_type) REFERENCES cfps_types(id)
);

CREATE TABLE papers (
    -- This papers.id is an implementation detail that is not exposed.  
    -- It is not in general the same as a CFPS id.
    id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cfps_id         INTEGER UNSIGNED,

    version_created DATE NOT NULL,
    title           TEXT NOT NULL,
    language        TEXT NOT NULL,
    description     TEXT NOT NULL,
    keywords        TEXT NOT NULL,
    version         TEXT NOT NULL,
    changelog       TEXT,

    -- Not appended to the field definition as MySQL 5.5 only honours them
    -- when given as separate FOREIGN KEY constraints.
    FOREIGN KEY (cfps_id) REFERENCES cfps(id)
) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

-- Add this afterwards as it creates a circular dependency.  As it's the 
-- 2nd index created, it'll be called cfps_ibfk_2.  MySQL 5.5 fails to 
-- honour the syntax for giving it an explicit name.
ALTER TABLE cfps ADD FOREIGN KEY (latest_version) REFERENCES papers(id);

CREATE TABLE cfps_references (
    cfps_id            INTEGER UNSIGNED NOT NULL,
    references_id      INTEGER UNSIGNED NOT NULL,

    -- Set to TRUE for a 'Comment' paper for its primary subject(s)
    is_primary_subject BOOLEAN NOT NULL DEFAULT FALSE,

    FOREIGN KEY (cfps_id) REFERENCES cfps(id),
    FOREIGN KEY (references_id) REFERENCES cfps(id)
);

-- A two-way version of cfps_references
CREATE VIEW cfps_see_also (cfps_id, references_id) AS
    SELECT cfps_id, references_id FROM cfps_references
    UNION SELECT references_id, cfps_id FROM cfps_references;

