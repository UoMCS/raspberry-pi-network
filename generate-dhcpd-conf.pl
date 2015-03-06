#!/usr/bin/env perl

use 5.014;

use strict;
use warnings;
use autodie;

use DBI qw(:sql_types);
use Template::Toolkit::Simple;
use File::Slurp qw ( read_file write_file );
use DateTime;

my $datetime = DateTime->now;

my $config_autogen = "# DO NOT EDIT THIS FILE, IT IS AUTOMATICALLY GENERATED FROM A SCRIPT\n";
$config_autogen .= "# For full details check the documentation at: http://man.ac.uk/gG0U42\n";
$config_autogen .= '# Autogenerated: ' . $datetime->ymd . ' ' . $datetime->hms . "\n";

my $config_header = read_file('dhcpd.conf.header');
my $config_hosts = '';

my $output_file = 'dhcpd.conf';
my $db_file = 'devices.db';

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '');
$dbh->{RaiseError} = 1;

my $sql = 'SELECT academic_year, serial_number, mac_address, ip_address FROM devices WHERE active = ?';
my $sth = $dbh->prepare($sql);
$sth->bind_param(1, 1, { TYPE => SQL_INTEGER });
$sth->execute();

while (my $row = $sth->fetchrow_hashref)
{
  my $padded_serial = sprintf('%04d', $row->{'serial_number'});
  my $short_year = $row->{'academic_year'} - 2000;

  my %data = (
    'year' => $short_year,
    'serial_number' => $padded_serial,
    'mac_address' => $row->{'mac_address'},
    'ip_address' => $row->{'ip_address'}
  );

  $config_hosts	.= "\n";
  $config_hosts .= tt->render('client-device.tt', \%data);
}

$dbh->disconnect;

write_file($output_file, $config_autogen . $config_header . $config_hosts);
