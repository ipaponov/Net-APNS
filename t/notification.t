use strict;
use warnings;

Test::Class->runtests;

package Test::Notification;
use base qw(Test::Class);
use Test::More;
use Test::Moose;
use Test::Mouse;
use Net::APNS::Notification;
use Net::SSLeay;

sub test_init_notificaion : Test(setup) {
    my $self = shift;
    $self->{notify} = Net::APNS::Notification->new(
         cert   => "cert.pem",
         key    => "key.pem",
         passwd => "passwd",
         devicetoken => "xxxxxxxx xxxx xxxx xxxx xxxxxxxx",
    );
}

sub notify_attribute : Tests(7) {
    my $Notify = shift->{notify};
    has_attribute_ok ($Notify, "port", "notifyport");
    has_attribute_ok ($Notify, "message", "message");
    has_attribute_ok ($Notify, "badge", "badge");
    has_attribute_ok ($Notify, "alert", "alert");
    has_attribute_ok ($Notify, "devicetoken", "devicetoken");
    has_attribute_ok ($Notify, "sandbox", "sandbox");
    has_attribute_ok ($Notify, "passwd", "passwd");
}

sub default_value : Tests(5) {
    my $notify = shift->{notify};
    is ($notify->type_pem, &Net::SSLeay::FILETYPE_PEM);
    is ($notify->message, '');
    is ($notify->badge, 0);
    is ($notify->sandbox, 0);
    is_deeply ($notify->alert, {});
}

1;