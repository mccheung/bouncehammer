# $Id: Google.pm,v 1.5.2.9 2013/08/30 05:55:02 ak Exp $
# -Id: Google.pm,v 1.2 2010/07/04 23:45:49 ak Exp -
# -Id: Google.pm,v 1.1 2009/08/29 08:50:36 ak Exp -
# -Id: Google.pm,v 1.1 2009/07/31 09:04:38 ak Exp -
# Copyright (C) 2009-2013 Cubicroot Co. Ltd.
# Kanadzuchi::MTA::US::

  ####                        ###          
 ##  ##  ####   ####   #####   ##   ####   
 ##     ##  ## ##  ## ##  ##   ##  ##  ##  
 ## ### ##  ## ##  ## ##  ##   ##  ######  
 ##  ## ##  ## ##  ##  #####   ##  ##      
  ####   ####   ####      ##  ####  ####   
                      #####                
package Kanadzuchi::MTA::US::Google;
use strict;
use warnings;
use base 'Kanadzuchi::MTA';

#  ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ 
# ||G |||l |||o |||b |||a |||l |||       |||v |||a |||r |||s ||
# ||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
#
my $RxFromGmail = {
    'from'    => qr/[@]googlemail[.]com[>]?\z/,
    'begin'   => qr/Delivery to the following recipient/,
    'start'   => qr/Technical details of (?:permanent|temporary) failure:/,
    'error'   => qr/The error that the other server returned was:/,
    'endof'   => qr/\A----- Original message -----\z/,
    'subject' => qr/Delivery[ ]Status[ ]Notification/,
};

my $RxTempError = {
    'expired' => [
        qr/DNS Error: Could not contact DNS servers/,
        qr/Delivery to the following recipient has been delayed/,
    ],
};

my $RxPermError = {
    'expired' => qr/The recipient server did not accept our requests to connect/,
    'hostunknown' => [
        qr/DNS Error: Domain name not found/,
        qr/DNS Error: DNS server returned answer with no data/,
    ],
};

my $StateCodeMap = {
    # Technical details of permanent failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 500 Remote server does not support TLS (state 6).
    '6'  => { 'xsmtp' => 'MAIL', 'causa' => 'systemerror', 'error' => 'p' },

    # http://www.google.td/support/forum/p/gmail/thread?tid=08a60ebf5db24f7b&hl=en
    # Technical details of permanent failure:
    # Google tried to deliver your message, but it was rejected by the recipient domain. 
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 535 SMTP AUTH failed with the remote server. (state 8).
    '8'  => { 'xsmtp' => 'AUTH', 'causa' => 'systemerror', 'error' => 'p' },

    # http://www.google.co.nz/support/forum/p/gmail/thread?tid=45208164dbca9d24&hl=en
    # Technical details of temporary failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 454 454 TLS missing certificate: error:0200100D:system library:fopen:Permission denied (#4.3.0) (state 9).
    '9'  => { 'xsmtp' => 'AUTH', 'causa' => 'systemerror', 'error' => 't' },

    # http://www.google.com/support/forum/p/gmail/thread?tid=5cfab8c76ec88638&hl=en
    # Technical details of permanent failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 500 Remote server does not support SMTP Authenticated Relay (state 12). 
    '12' => { 'xsmtp' => 'AUTH', 'causa' => 'systemerror', 'error' => 'p' },

    # Technical details of permanent failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was: 
    # 550 550 5.7.1 <****@gmail.com>... Access denied (state 13).
    '13' => { 'xsmtp' => 'MAIL', 'causa' => 'rejected', 'error' => 'p' },

    # Technical details of permanent failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 550 550 5.1.1 <******@*********.**>... User Unknown (state 14).
    # 550 550 5.2.2 <*****@****.**>... Mailbox Full (state 14).
    # 
    '14' => { 'xsmtp' => 'RCPT', 'causa' => 'userunknown', 'error' => 'p' },

    # http://www.google.cz/support/forum/p/gmail/thread?tid=7090cbfd111a24f9&hl=en
    # Technical details of permanent failure:
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 550 550 5.7.1 SPF unauthorized mail is prohibited. (state 15).
    # 554 554 Error: no valid recipients (state 15). 
    '15' => { 'xsmtp' => 'DATA', 'causa' => 'filtered', 'error' => 'p' },

    # http://www.google.com/support/forum/p/Google%20Apps/thread?tid=0aac163bc9c65d8e&hl=en
    # Technical details of permanent failure:
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 550 550 <****@***.**> No such user here (state 17).
    # 550 550 #5.1.0 Address rejected ***@***.*** (state 17).
    '17' => { 'xsmtp' => 'DATA', 'causa' => 'filtered', 'error' => 'p' },

    # Technical details of permanent failure: 
    # Google tried to deliver your message, but it was rejected by the recipient domain.
    # We recommend contacting the other email provider for further information about the
    # cause of this error. The error that the other server returned was:
    # 550 550 Unknown user *****@***.**.*** (state 18).
    '18' => { 'xsmtp' => 'DATA', 'causa' => 'filtered', 'error' => 'p' },
};

#  ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
# ||C |||l |||a |||s |||s |||       |||M |||e |||t |||h |||o |||d |||s ||
# ||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
sub version { '2.1.8' };
sub description { 'Google Gmail' };
sub xsmtpagent { 'X-SMTP-Agent: US::Google'.qq(\n); }
sub emailheaders {
    # +-+-+-+-+-+-+-+-+-+-+-+-+
    # |e|m|a|i|l|h|e|a|d|e|r|s|
    # +-+-+-+-+-+-+-+-+-+-+-+-+
    #
    # @Description  Required email headers
    # @Param        <None>
    # @Return       (Ref->Array) Header names
    my $class = shift;
    return [ 'X-Failed-Recipients' ];
}

sub reperit {
    # +-+-+-+-+-+-+-+
    # |r|e|p|e|r|i|t|
    # +-+-+-+-+-+-+-+
    #
    # @Description  Detect an error via Google(Gmail)
    # @Param <ref>  (Ref->Hash) Message header
    # @Param <ref>  (Ref->String) Message body
    # @Return       (String) Pseudo header content
    my $class = shift;
    my $mhead = shift || return q();
    my $mbody = shift || return q();

    #   ____                 _ _ 
    #  / ___|_ __ ___   __ _(_) |
    # | |  _| '_ ` _ \ / _` | | |
    # | |_| | | | | | | (_| | | |
    #  \____|_| |_| |_|\__,_|_|_|
    #                            
    # Google Mail: GMail
    # From: Mail Delivery Subsystem <mailer-daemon@googlemail.com>
    # Received: from vw-in-f109.1e100.net [74.125.113.109] by ...
    #
    # * Check the body part
    #   This is an automatically generated Delivery Status Notification
    #   Delivery to the following recipient failed permanently:
    #
    #        recipient-address-here@example.jp
    #
    #   Technical details of permanent failure: 
    #   Google tried to deliver your message, but it was rejected by the
    #   recipient domain. We recommend contacting the other email provider
    #   for further information about the cause of this error. The error
    #   that the other server returned was: 
    #   550 550 <recipient-address-heare@example.jp>: User unknown (state 14).
    #
    #   -- OR --
    #   THIS IS A WARNING MESSAGE ONLY.
    #   
    #   YOU DO NOT NEED TO RESEND YOUR MESSAGE.
    #   
    #   Delivery to the following recipient has been delayed:
    #   
    #        mailboxfull@example.jp
    #   
    #   Message will be retried for 2 more day(s)
    #   
    #   Technical details of temporary failure:
    #   Google tried to deliver your message, but it was rejected by the recipient
    #   domain. We recommend contacting the other email provider for further infor-
    #   mation about the cause of this error. The error that the other server re-
    #   turned was: 450 450 4.2.2 <mailboxfull@example.jp>... Mailbox Full (state 14).
    #
    #   -- OR --
    #
    #   Delivery to the following recipient failed permanently:
    #   
    #        userunknown@example.jp
    #   
    #   Technical details of permanent failure:=20
    #   Google tried to deliver your message, but it was rejected by the server for=
    #    the recipient domain example.jp by mx.example.jp. [192.0.2.59].
    #   
    #   The error that the other server returned was:
    #   550 5.1.1 <userunknown@example.jp>... User Unknown
    #
    return q() unless $mhead->{'from'} =~ $RxFromGmail->{'from'};
    return q() unless $mhead->{'subject'} =~ $RxFromGmail->{'subject'};

    my $phead = q();        # (String) Pusedo header
    my $pbody = q();        # (String) Boby part for rewriting
    my $pstat = q();        # (String) Pseudo D.S.N.
    my $causa = 'onhold';   # (String) Error reason: userunknown, filtered, mailboxfull...
    my $xsmtp = q();        # (String) SMTP Command in transcript of session
    my $error = 'p';        # (String) p = permanent, t = temporary

    # (String) X-Final-Recipients: header or email address in the body.
    my $rcptintxt = q();    # (String) Content of X-Failed-Recipients: header
    my $statintxt = q();    # (String) Status(D.S.N.) in the error message.
    my $rhostsaid = q();    # (String) Error message from remote host
    my $statecode = 0;      # (Integer) (state xx). at the end of the error message.

    if( defined $mhead->{'x-failed-recipients'} ) {
        $rcptintxt = $1 if $mhead->{'x-failed-recipients'} =~ m/\A[ ]?(.+[@].+)[ ]*\z/i;
    }

    EACH_LINE: foreach my $el ( split( qq{\n}, $$mbody ) ) {

        if( ($el =~ $RxFromGmail->{'begin'}) .. ($el =~ $RxFromGmail->{'endof'}) ) {
            # Technical details of permanent failure:=20
            # Google tried to deliver your message, but it was rejected by the recipient =
            # domain. We recommend contacting the other email provider for further inform=
            # ation about the cause of this error. The error that the other server return=
            # ed was: 554 554 5.7.0 Header error (state 18).
            #
            # -- OR --
            #
            # Technical details of permanent failure:=20
            # Google tried to deliver your message, but it was rejected by the server for=
            # the recipient domain example.jp by mx.example.jp. [192.0.2.49].
            #
            # The error that the other server returned was:
            # 550 5.1.1 <userunknown@example.jp>... User Unknown
            #
            $el =~ s{=\z}{};
            if( $el =~ m/\A\s+(.+[@].+)\z/ ) {
                $rcptintxt = Kanadzuchi::Address->canonify( $1 );
                $rcptintxt = q() unless Kanadzuchi::RFC2822->is_emailaddress( $rcptintxt )

            } else {
                next if $el =~ $RxFromGmail->{'endof'};
                $rhostsaid .= $el;
            }
            next;
        }
    }

    return q() unless $rhostsaid;

    $rhostsaid =~ s/\A.*$RxFromGmail->{'begin'}.+$RxFromGmail->{'error'} ?//;
    $rhostsaid =~ s/([(]state \d+[)][.]).+\z/$1/;
    $rhostsaid =~ y{ }{}s;

    $statecode = $1 if( $rhostsaid =~ m/[(]state[ ](\d+)[)][.]/ );        # (state 18).
    $statintxt = $1 if( $rhostsaid =~ m/[(][#]([45][.]\d[.]\d+)[)]/       # (#5.1.1)
                    ||  $rhostsaid =~ m/\d{3}[ ]\d{3}[ ]([45][.]\d[.]\d+)/ ); # 550 550 5.1.1

    if( $rhostsaid =~ m/\d{3}[ ]\d{3}[ ](\d[.]\d[.]\d+)[ ][<](.+?)[>]:?.+\z/ ) {
        # There is D.S.N. code in the body part.
        # 550 550 5.1.1 <userunknown@example.jp>... User Unknown (state 14).
        # 450 450 4.2.2 <mailboxfull@example.jp>... Mailbox Full (state 14).
        $statintxt ||= $1;
        $rcptintxt ||= $2;

    } else {
        $rcptintxt ||= Kanadzuchi::Address->canonify( $rhostsaid );
        $rcptintxt ||= $1 if $rhostsaid =~ m/\s+([^\s]+[@][^\s]+)\s+[(]state \d+[)][.]\z/;
    }

    # New format of a bounce mail from Google, there is no (state xx).
    $statintxt ||= $1 if $rhostsaid =~ m/([45][.]\d[.]\d+)/;

    if( ! $statintxt || $statintxt =~ m/\A[45][.]0[.]0\z/ ) {
        # There is NO D.S.N. code in the body part or D.S.N. is 5.0.0,4.0.0.
        if( $statecode ) {

            if( grep { $statecode == $_ } keys %$StateCodeMap ) {
                $xsmtp = $StateCodeMap->{ $statecode }->{'xsmtp'};
                $causa = $StateCodeMap->{ $statecode }->{'causa'};
                $error = $StateCodeMap->{ $statecode }->{'error'};

            } else {
                $causa = 'onhold';
            }

        } else {

            if( grep { $rhostsaid =~ $_ } @{ $RxTempError->{'expired'} } ) {
                # Technical details of temporary failure: 
                # The recipient server did not accept our requests to connect. 
                # Learn more at http://mail.google.com/support/bin/answer.py?answer=7720 
                # [test.example.jp. (0): Connection timed out]
                $causa = 'expired';
                $error = 't';

            } elsif( $rhostsaid =~ $RxPermError->{'expired'} ) {
                # Technical details of permanent failure: 
                # The recipient server did not accept our requests to connect.
                # Learn more at http://mail.google.com/support/bin/answer.py?answer=7720 
                # [test.example.jp (1): Connection timed out]
                $causa = 'expired';
                $error = 'p';

            } elsif( grep { $rhostsaid =~ $_ } @{ $RxPermError->{'hostunknown'} } ) {
                # Technical details of permanent failure: 
                # DNS Error: Domain name not found
                $causa = 'hostunknown';
                $error = 'p';

            } else {
                # Unsupported error message in body part.
                $causa = 'undefined';
            }

            $rhostsaid =~ s/\A.+$RxFromGmail->{'start'}//;
            $rhostsaid =~ s/Learn more at.+\[(.+)\].+\z/$1/;
            $rhostsaid =~ s/\A //g;
            $rhostsaid =~ s/ \z//g;
        }

        $pstat = Kanadzuchi::RFC3463->status( $causa, $error, 'i' );

    } else {
        $pstat = $statintxt;
    }

    return q() unless $rcptintxt;
    $phead .= __PACKAGE__->xsmtpcommand( $xsmtp );
    $phead .= __PACKAGE__->xsmtpagent;
    $phead .= __PACKAGE__->xsmtpdiagnosis( $rhostsaid );
    $phead .= __PACKAGE__->xsmtpstatus( $pstat );
    $phead .= __PACKAGE__->xsmtprecipient( $rcptintxt );
    $phead .= 'To: '.$rcptintxt.qq(\n);

    return $phead;
}

1;
__END__
