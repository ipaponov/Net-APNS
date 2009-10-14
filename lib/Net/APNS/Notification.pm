package Net::APNS::Notification;

use Moose;
use Net::SSLeay qw/die_now die_if_ssl_error/;
use Socket;
use Encode qw(decode encode);
use JSON::XS;
our $VERSION = '0.01';

has message => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
);

has badge => (
    is       => 'rw',
    isa      => 'Int',
    default  => 0,
);

has devicetoken => (
    is       => 'rw',
    isa      => 'Str',
    trigger  => sub {
        if (@_ >= 2) {
            my $dt = $_[1];
            $dt =~ s/\s//g;
            $_[0]->{devicetoken} = $dt;
        }
    }
);

has cert => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has key => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has passwd => (
    is       => 'rw',
    required => 1,
);

has type_pem => (
    is      => 'ro',
    default => &Net::SSLeay::FILETYPE_PEM,
);

sub apple_serv_params {
    my $self = shift;
    return sockaddr_in($self->port, inet_aton($self->host));
}

sub host {
    my $self = shift;
    my $host;
    if ($self->sandbox) {
        $host = 'gateway.sandbox.push.apple.com';
    } else {
        $host = 'gateway.push.apple.com';
    }
    return $host;
}

has port => (
    is       => 'rw',
    isa      => 'Int',
    default  => 2195,
);

has sandbox => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1,
);

sub _message_encode {
    my $self = shift;
    return encode('unicode', decode('utf8', $self->message));
}

sub _payload {
    my $self = shift;
    my $jsonxs = JSON::XS->new->utf8(1)->encode({
        aps => {
            alert => $self->_message_encode,
            badge => $self->badge,
        }
    });
    $jsonxs =~ s/("badge":)"([^"]+)"/$1$2/;
    return chr(0).pack('n',32).pack('H*',$self->devicetoken).pack('n',length($jsonxs)).$jsonxs;
}

sub write {
    my ($self, $args) = @_;
    if ($args->{devicetoken}) { $self->devicetoken($args->{devicetoken}); }
    if ($args->{message}) { $self->message($args->{message}); }
    if ($args->{badge}) { $self->badge($args->{badge}); }
     
    $Net::SSLeay::trace = 4;
    $Net::SSLeay::ssl_version = 10;
    
    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();

    my $socket;
    socket ($socket, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
    connect($socket, $self->apple_serv_params) or die "Connect: $!";
    
    my $ctx = Net::SSLeay::CTX_new() or die_now("Failed to create SSL_CTX $!.");
    Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
    die_if_ssl_error("ssl ctx set options");
    Net::SSLeay::CTX_set_default_passwd_cb($ctx, sub { $self->passwd });
    Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, $self->key, $self->type_pem);
    die_if_ssl_error("private key");
    Net::SSLeay::CTX_use_certificate_file ($ctx, $self->cert, $self->type_pem);
    die_if_ssl_error("certificate");
    
    my $ssl = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd($ssl, fileno($socket));
    Net::SSLeay::connect($ssl) or die_now("Failed SSL connect ($!)");

    Net::SSLeay::write($ssl, $self->_payload);
    
    CORE::shutdown($socket, 1);
    Net::SSLeay::free($ssl);
    Net::SSLeay::CTX_free($ctx);
    close($socket);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
__END__

=head1 NAME

Net::APNS::Notification - Notify client in Apple Push Notification Service for perl.

=head1 SYNOPSIS

  use Net::APNS::Notification;
  my $APNS = Net::APNS::Notification->new({
      cert => "cert.pem",
      key  => "key.pem",
      passwd => "passwd.pem",
  });
  $APNS->write({
      devicetoken => "token",
      message     => "message",
      badge       => 0,
  });

=head1 DESCRIPTION

Net::APNS::Notification is Apple Push Notification Service - push client.
Push message to iPhone and get unavalble-devicetoken.

=head1 AUTHOR

haoyayoi E<lt>st.hao.yayoi@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
