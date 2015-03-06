#!/usr/bin/env perl

use 5.014;

use strict;
use warnings;
use autodie;

use DBI qw(:sql_types);

my $log_file = 'maclog.log';
my $db_file = 'devices.db';

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '');
$dbh->{RaiseError} = 1;

open LOG_FILE, '<', $log_file;

while (my $line = <LOG_FILE>)
{
  chomp($line);

  # Log file has the format: $mac_address,$academic_year/$serial_number
  my ($mac_address, $code) = split(',', $line);
  my ($academic_year, $serial_number) = split('/', $code);

  # Force serial number to be treated as integer, otherwise we will get a warning
  # when we try and insert it into a numeric column
  $serial_number = int($serial_number);

  # MAC log file stores addresses in two digit format, add 2000 to get full digit format
  $academic_year += 2000;

  # Check whether thsi device has already been logged, as we do not want to
  # create duplicate entries
  my $sql = 'SELECT COUNT(id) AS device_count FROM devices WHERE mac_address = ? LIMIT 1';
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $mac_address, { TYPE => SQL_VARCHAR });
  $sth->execute();
  my $row = $sth->fetchrow_hashref;

  if ($row->{'device_count'} == 0)
  {
    $sql = 'INSERT INTO devices (academic_year, serial_number, mac_address) VALUES (?, ?, ?)';
    $sth = $dbh->prepare($sql);
    $sth->bind_param(1, $academic_year, { TYPE => SQL_INTEGER });
    $sth->bind_param(2, $serial_number, { TYPE => SQL_INTEGER });
    $sth->bind_param(3, $mac_address, { TYPE => SQL_VARCHAR });
    $sth->execute();
  }
}

close LOG_FILE;

$dbh->disconnect();
