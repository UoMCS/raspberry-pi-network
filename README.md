# Raspberry Pi network

In the School of Computer Science we have a separate private network for hosting
Raspberry Pi devices which are given out to first year students. Devices on the
network configure using DHCP and will only receive an IP address if their MAC
address matches a known list.

The scripts in this repository automate the following tasks:

 1. Importing a log of MAC addresses into a SQLite database.
 1. Assigning IP addresses to 'active' devices.
 1. Generating the DHCP daemon configuration file.

Devices are considered to be 'active' for four years from first registration,
as this is the maximum length of most of our full-time undergraduate degree
courses (there are exceptions, but the default is sufficient to catch the
vast majority of cases).
