#!/usr/bin/perl

#
# ============================== SUMMARY =====================================
#
# Program   : smsalert.pl
# Version   : 1.0
# Date      : April 3 2020
# Author    : SMSAlert
# Copyright : SMSAlert 2020 All rights reserved.
# Summary   : This plugin sends SMS alerts through the SMS Alert API
# License   : ISC
#
# =========================== PROGRAM LICENSE =================================
#
# Copyright (c) 2020 SMSAlert <support@cozyvision.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# =============================	MORE INFO ======================================
# 
# As released this plugin requires a SMSAlert account to send text
# messages.  To setup a SMSAlert account visit:
#   https://www.ssmalert.co.in/
#
# The latest version of this plugin can be found on GitHub at:
#   http://github.com/SMSAlert/Nagios-Plugins
#
# ============================= SETUP NOTES ====================================
# 
# Copy this file to your Nagios plugin folder
# On a Centos install this is /usr/lib/nagios/plugins (32 bit) 
# or /usr/lib64/nagios/plugins (64 bit) other distributions may vary.
#
# NAGIOS SETUP
#
# 1. Create the SMS notification commands.  (Commonly found in commands.cfg)
#    Don't forget to add your SMSAlert API Key.
#
# define command{
# 	command_name    notify-by-sms
#	command_line    $USER1$/smsalert.pl -k API_KEY -t $CONTACTPAGER$ -f Nagios -m "Service: $SERVICEDESC$\\nHost: $HOSTNAME$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\nInfo: $SERVICEOUTPUT$\\nDate: $LONGDATETIME$"
# }
#
# define command{
#	command_name    host-notify-by-sms
#	command_line    $USER1$/smsalert.pl -k API_KEY -t $CONTACTPAGER$ -f Nagios -m "Host $HOSTNAME$ is $HOSTSTATE$\\nInfo: $HOSTOUTPUT$\\nTime: $LONGDATETIME$"
# }
#
# 2. In your nagios contacts (Commonly found on contacts.cfg) add 
#    the SMS notification commands:
#
#    service_notification_commands	notify-by-sms
#    host_notification_commands		host-notify-by-sms
#
# 3. Add a pager number to your contacts, make sure it has the international 
#    prefix, e.g. 91 for INDIA or 1 for USA, without a leading 00 or +.
#
#    pager	918010551055  
#


use strict;
use Getopt::Long;
use LWP;
use URI::Escape;

my $version = '1.0';
my $verbose = undef; # Turn on verbose output
my $apikey = undef;
my $to = undef;
my $senderid = "Nagios";
my $message = undef;

sub print_version { print "$0: version $version\n"; exit(1); };
sub verb { my $t=shift; print "VERBOSE: ",$t,"\n" if defined($verbose) ; }
sub print_usage {
        print "Usage: $0 [-v] -k <apikey> -t <to> [-f <senderid>] -m <message>\n";
}

sub help {
        print "\nNotify by SMS Plugin ", $version, "\n";
        print " SMSAlert - http://www.smsalert.co.in/\n\n";
        print_usage();
        print <<EOD;
-h, --help
        print this help message
-V, --version
        print version
-v, --verbose
        print extra debugging information
-k, --apikey=APIKEY
	SMSAlert API Key
-t, --to=TO
        mobile number to send SMS to in international format
-f, --senderid=SENDERID (Optional)
        senderid (exact 6 chars)
-m, --message=MESSAGE
        content of the text message
EOD
	exit(1);
}

sub check_options {
        Getopt::Long::Configure ("bundling");
        GetOptions(
                'v'     => \$verbose,		'verbose'       => \$verbose,
                'V'     => \&print_version,	'version'       => \&print_version,
		'h'	=> \&help,		'help'		=> \&help,
		'k=s'	=> \$apikey,		'apikey=s'	        => \$apikey,
                't=s'   => \$to,        	'to=s'          => \$to,
                'f=s'   => \$senderid,      	'senderid=s'        => \$senderid,
                'm=s'   => \$message,   	'message=s'     => \$message
        );

	if (!defined($apikey))
		{ print "ERROR: No API Key defined!\n"; print_usage(); exit(1); }
        if (!defined($to))
                { print "ERROR: No to defined!\n"; print_usage(); exit(1); }
        if (!defined($message))
                { print "ERROR: No message defined!\n"; print_usage(); exit(1); }

	if($to!~/^\d{7,15}$/) {
                { print "ERROR: Invalid to number!\n"; print_usage(); exit(1); }
	}
	verb "apikey = $apikey";
        verb "to = $to";
        verb "senderid = $senderid";
        verb "message = $message";
}

sub SendSMS {
	my $apikey = shift;
	my $to = shift;
	my $senderid = shift;
	my $message = shift;

	# URL Encode parameters before making the HTTP POST
	$apikey        = uri_escape($apikey);
	$to         = uri_escape($to);
	$senderid       = uri_escape($senderid);
	$message    = uri_escape($message);

	my $result;
	my $server = 'https://www.smsalert.co.in/api/push.json';
	my $post = 'apikey=' . $apikey;
	$post .= '&mobileno='.$to;
	$post .= '&sender='.$senderid;
	$post .= '&text='.$message;
	
	verb("Post Data: ".$post);
	
        my $ua = LWP::UserAgent->new();
	$ua->timeout(30);
	$ua->agent('Nagios-SMS-Plugin/'.$version);
        my $req = HTTP::Request->new('POST',$server);
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($post);
	my $res = $ua->request($req);

	verb("POST Status: ".$res->status_line);
	verb("POST Response: ".$res->content);
	
	if($res->is_success) {
		if($res->content=~/error/i) {
			print $res->content;
			$result = 1;
		} else {
			$result = 0;
		}
	} else {
		$result = 1;
		print $res->status_line;
	}

        return $result;
}


check_options();
my $send_result = SendSMS($apikey, $to, $senderid, $message);

exit($send_result);

