#!/usr/bin/env perl

use 5.014;

use strict;
use warnings;
use autodie;

use DateTime;
use DBI qw(:sql_types);

# IP blocks - we allocate two class C blocks per year
# so these must be kept in pairs
my %ip_blocks = (
  2013 => ['10.2.232', '10.2.233'],
  2014 => ['10.2.234', '10.2.235'],
  2015 => ['10.2.236', '10.2.237'],
  2016 => ['10.2.238', '10.2.239'],
);

my $datetime = DateTime->now;
my $academic_year = $datetime->year;

# Academic year does not roll over until September (month 9)
if ($datetime->month < 9)
{
  $academic_year--;
}

my $cutoff_year = $academic_year - 4;

my $db_file = 'devices.db';

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '');
$dbh->{RaiseError} = 1;

# Deactivate any devices registered on or before the cutoff year
my $sql = 'UPDATE devices SET active = ? WHERE academic_year <= ?';
my $sth = $dbh->prepare($sql);
$sth->bind_param(1, 0, { TYPE => SQL_INTEGER });
$sth->bind_param(2, $cutoff_year, { TYPE => SQL_INTEGER });
$sth->execute();

# Fetch all the devices which are registered after the cutoff year and are inactive
$sql = "SELECT id, academic_year, serial_number FROM devices WHERE academic_year > ? AND active = ?";
$sth = $dbh->prepare($sql);
$sth->bind_param(1, $cutoff_year, { TYPE => SQL_INTEGER });
$sth->bind_param(2, 0, { TYPE => SQL_INTEGER });
$sth->execute();

while (my $row = $sth->fetchrow_hashref)
{
  my $serial_number = $row->{'serial_number'};
  my $ip_address = undef;

  # IP address assignments are based on the serial number.
  # Since we do not want an IP address ending in .0 (or .255), we override
  # the serial number by setting it to 500
  if ($serial_number == 0)
  {
    $serial_number = 500;
  }

  if ($serial_number <= 250)
  {
    $ip_address = $ip_blocks{$row->{'academic_year'}}[0] . ".$serial_number";
  }
  else
  {
    # First block goes up to 250, if serial is higher than this then use the second block
    $serial_number -= 250;
    $ip_address = $ip_blocks{$row->{'academic_year'}}[1] . ".$serial_number";
  }

  my $address_sql = 'UPDATE devices SET ip_address = ?, active = ? WHERE id = ?';
  my $address_sth = $dbh->prepare($address_sql);
  $address_sth->bind_param(1, $ip_address, { TYPE => SQL_VARCHAR });
  $address_sth->bind_param(2, 1, { TYPE => SQL_INTEGER });
  $address_sth->bind_param(3, $row->{'id'}, { TYPE => SQL_INTEGER });
  $address_sth->execute();
}

$dbh->disconnect();
