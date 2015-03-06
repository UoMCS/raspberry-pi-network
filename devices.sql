CREATE TABLE devices
(
	id integer primary key autoincrement,
	academic_year integer not null,
	serial_number integer not null,
	mac_address text not null unique,
	ip_address text,
	active integer not null default 0
);