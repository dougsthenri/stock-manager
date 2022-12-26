/*
Scheme for creating the electronic components database for stock management.
Version: 1.3.
*/

CREATE TABLE "stock" (
    "component_id"          INTEGER PRIMARY KEY AUTOINCREMENT, -- ROWID
    "part_number"           TEXT NOT NULL,
    "manufacturer"          TEXT,
    "quantity"              INTEGER NOT NULL DEFAULT 0 CHECK("quantity" >= 0),
    "component_type"        TEXT NOT NULL,
    "voltage_rating"        REAL,   -- Volts
    "current_rating"        REAL,   -- Amperes
    "power_rating"          REAL,   -- Watts
    "resistance_rating"     REAL,   -- Ohms
    "inductance_rating"     REAL,   -- Henries
    "capacitance_rating"    REAL,   -- Farads
    "frequency_rating"      REAL,   -- Hertz
    "tolerance_rating"      REAL,   -- Percent
    "package_code"          TEXT,   -- Codes in inches
    "comments"              TEXT,
    UNIQUE("part_number", "manufacturer")
);

CREATE TABLE "acquisitions" (
    "id"                INTEGER PRIMARY KEY AUTOINCREMENT, -- ROWID
    "fk_component_id"   INTEGER NOT NULL,
    "quantity"          INTEGER NOT NULL CHECK("quantity" > 0),
    "date_acquired"     TEXT, -- ISO 8601 (yyyy-mm-ddT00:00:00±hh:mm)
    "origin"            TEXT,
	FOREIGN KEY("fk_component_id") REFERENCES "stock"("component_id") ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE "expenditures" (
    "id"                INTEGER PRIMARY KEY AUTOINCREMENT, -- ROWID
    "fk_component_id"   INTEGER NOT NULL,
    "quantity"          INTEGER NOT NULL CHECK("quantity" > 0),
    "date_spent"        TEXT, -- ISO 8601 (yyyy-mm-ddT00:00:00±hh:mm)
    "destination"       TEXT,
	FOREIGN KEY("fk_component_id") REFERENCES "stock"("component_id") ON UPDATE CASCADE ON DELETE CASCADE
)
