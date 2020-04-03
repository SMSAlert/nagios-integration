## nagios-smsalert-plugin
Plugins for Nagios monitoring software to send sms

##SETUP

## As released this plugin requires a SMSAlert account to send text messages.  To setup a SMSAlert account visit:
   https://www.ssmalert.co.in/

## The latest version of this plugin can be found on GitHub at:
   http://github.com/SMSAlert/nagios-smsalert-plugin

## Copy this file to your Nagios plugin folder
 On a Centos install this is /usr/lib/nagios/plugins (32 bit) 
 or /usr/lib64/nagios/plugins (64 bit) other distributions may vary.

## Create the SMS notification commands.  (Commonly found in commands.cfg)
    Don't forget to add your SMSAlert API Key.

 define command{
 	command_name    notify-by-sms
	command_line    $USER1$/smsalert.pl -k API_KEY -t $CONTACTPAGER$ -f Nagios -m "Service: $SERVICEDESC$\\nHost: $HOSTNAME$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\nInfo: $SERVICEOUTPUT$\\nDate: $LONGDATETIME$"
 }

 define command{
	command_name    host-notify-by-sms
	command_line    $USER1$/smsalert.pl -k API_KEY -t $CONTACTPAGER$ -f Nagios -m "Host $HOSTNAME$ is $HOSTSTATE$\\nInfo: $HOSTOUTPUT$\\nTime: $LONGDATETIME$"
 }

## In your nagios contacts (Commonly found on contacts.cfg) add 
    the SMS notification commands:

    service_notification_commands	notify-by-sms
    host_notification_commands		host-notify-by-sms

## Add a pager number to your contacts, make sure it has the international 
    prefix, e.g. 91 for INDIA or 1 for USA, without a leading 00 or +.

    pager	918010551055  

