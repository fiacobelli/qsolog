create table qso (
    qso_id integer primary key asc,
    my_callsign text,
    call text,
    qso_date integer,
    time_on integer,
    band text,
    mode text,
    sat_mode text,
    sat_name text,
    comment text,
    other text
);

CREATE TABLE logbook (
    book_id integer,
    qso_id integer
);

CREATE TABLE logname (
    book_id integer primary key,
    name text,
    date_created integer
);