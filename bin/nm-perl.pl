#!/usr/bin/perl

use Net::DBus;

my $bus              = Net::DBus->system;
my $nm               = $bus->get_service("org.freedesktop.NetworkManager");
my $device_object    = $nm->get_object("/org/freedesktop/NetworkManager", "org.freedesktop.NetworkManager");
my $device           = $device_object->GetDeviceByIpIface("wlan0");
my $device_props     = $nm->get_object($device, "org.freedesktop.DBus.Properties");
my $connection       = $device_props->Get("org.freedesktop.NetworkManager.Device", "ActiveConnection");
my $connection_props = $nm->get_object($connection, "org.freedesktop.DBus.Properties");
my $access_point     = $connection_props->Get("org.freedesktop.NetworkManager.Connection.Active", "SpecificObject");
print("nm_ac = '".$access_point."'\n");
my $ap_props         = $nm->get_object($access_point, "org.freedesktop.DBus.Properties");

my %props            = %{$ap_props->GetAll("org.freedesktop.NetworkManager.AccessPoint")};

my $t = "nm_ac_table = {\n";
for my $k (keys %props)
{
    my $val = $props{$k};
    if ($k =~ /^Ssid$/) {$val =join('', map(chr, @{$val}))};
    $t .="    ".$k." = \"".$val."\",\n";
}
$t .= '}';

print($t);

