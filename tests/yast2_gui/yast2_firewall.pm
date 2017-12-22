# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: YaST2 Firewall UI test checks verious configurations and settings of firewall
# Make sure yast2 firewall can opened properly. Configurations can be changed and written correctly.
# Maintainer: Zaoliang Luo <zluo@suse.com>

use base "y2x11test";
use strict;
use testapi;
use utils;
use version_utils qw(is_sle sle_version_at_least is_leap leap_version_at_least);

sub susefirewall2 {
    # 	enter page interfaces and change zone for network interface
    assert_and_click("yast2_firewall_config_list");
    assert_screen "yast2_firewall_interfaces";
    assert_and_click("yast2_firewall_interface_zone_change");
    wait_still_screen(2);
    assert_and_click("yast2_firewall_interface_no-zone_assigned");
    wait_still_screen 1;
    wait_screen_change {
        send_key "down";
        send_key "ret"
    };
    wait_still_screen 1;
    send_key "alt-o";
    assert_screen "yast2_firewall_interfaces";

    # 	enter page Allowed Services and make  some changes
    assert_and_click("yast2_firewall_allowed-services");
    assert_and_click("yast2_firewall_service-to-allow");
    assert_and_click("yast2_firewall_service_http");
    send_key "alt-a";
    assert_screen "yast2_firewall_service_http_addded";

    #	enter page Broadcast and disable logging broadcast packets
    assert_and_click("yast2_firewall_broadcast");
    wait_still_screen 1;
    wait_screen_change { send_key "alt-l"; };
    send_key "alt-o";
    assert_screen "yast2_firewall_broadcast_no-logging";

    # 	enter page Logging Level and disable logging
    assert_and_click("yast2_firewall_logging-level");
    assert_and_click("yast2_firewall_do-not-log-any_accepted");
    assert_and_click("yast2_firewall_do-not-log-any_not-accepted");

    #	enter page Custom Rules and check ui
    assert_and_click("yast2_firewall_custom-rules");
    # verify Custom Rules page is displayed
    assert_screen("yast2_firewall_custom-rules-loaded");
    send_key "alt-a";
    assert_screen "yast2_firewall_add-new-allowing-rules";
    send_key "alt-c";
    wait_still_screen(2);

    #	Next to finish and exit
    send_key "alt-n";
    assert_screen "yast2_firewall_summary", 30;
    send_key "alt-f";
}

sub firewalld {
    # the inplementation of new firewall module is not completed yet.
    # see bsc#1072659 for more details.
    # So check layout and some basic stuffs only.

    # check menu entries
    assert_and_click 'firewall-options-menu';
    assert_and_click 'firewall-view-menu';
    assert_and_click 'firewall-help-menu';

    # check zones public and some details
    # Todo: check services, Ports, Protocols, Source Ports, Masquerading, Port Forwarding etc.
    # check configuration details for zones, services, ipsets, icmp types, helpers, direct configuration
    assert_screen 'firewall-zones-public';
    assert_and_click 'firewall-config-services';
    assert_screen 'firewall-config-services-list';
    assert_and_click 'firewall-ipsets';
    assert_screen 'firewall-ipsets-entry';

    # now close and exit
    assert_and_click 'firewall-file-menu';
    assert_and_click 'firewall-file-quit';

    # incomplete implementation
    record_soft_failure 'bsc#1072659';
}

sub run {
    my $self = shift;
    select_console 'root-console';
    zypper_call('in yast2-http-server apache2 apache2-prefork', timeout => 1200);
    if ((is_sle && sle_version_at_least('15')) || (is_leap && leap_version_at_least('15.0'))) {
        zypper_call('in firewall-config', timeout => 60);
        select_console 'x11', await_console => 0;
        $self->launch_yast2_module_x11('firewall', target_match => 'firewall-start-page', match_timeout => 60);
        firewalld;
    }
    else {
        select_console 'x11', await_console => 0;
        $self->launch_yast2_module_x11('firewall', match_timeout => 60);
        susefirewall2;
    }
}

1;
# vim: set sw=4 et:
