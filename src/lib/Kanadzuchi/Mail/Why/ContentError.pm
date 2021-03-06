# $Id: ContentError.pm,v 1.2.2.7 2013/08/30 05:55:25 ak Exp $
# Copyright (C) 2009,2010,2013 Cubicroot Co. Ltd.
# Kanadzuchi::Mail::Why::
                                                                                    
  ####                 ##                 ##   ######                               
 ##  ##  ####  ##### ###### ####  ##### ###### ##      #####  #####   ####  #####   
 ##     ##  ## ##  ##  ##  ##  ## ##  ##  ##   ####    ##  ## ##  ## ##  ## ##  ##  
 ##     ##  ## ##  ##  ##  ###### ##  ##  ##   ##      ##     ##     ##  ## ##      
 ##  ## ##  ## ##  ##  ##  ##     ##  ##  ##   ##      ##     ##     ##  ## ##      
  ####   ####  ##  ##   ### ####  ##  ##   ### ######  ##     ##      ####  ##      
package Kanadzuchi::Mail::Why::ContentError;
use base 'Kanadzuchi::Mail::Why';

#  ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
# ||C |||l |||a |||s |||s |||       |||M |||e |||t |||h |||o |||d |||s ||
# ||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
# Regular expressions of 'ContentError'
sub exemplaria {

    my $class = shift;
    return [ 
        # Rejected due to message contents: spam, virus or header.
        qr/\d+ denied \[[a-z]+\] .+[(]Mode: .+[)]/,
        qr/because the recipient is not accepting mail with attachments/,   # AOL Phoenix
        qr/because the recipient is not accepting mail with embedded images/,   # AOL Phoenix
        qr/blocked by policy: no spam please/,
        qr/blocked by spamAssassin/,        # rejected by SpamAssassin
        qr/domain .+ is a dead domain/,
        qr/mail appears to be unsolicited/, # rejected due to spam
        qr/message filtered/,
        qr/message filtered[.] please see the faqs section on spam/,
        qr/message rejected due to suspected spam content/,
        qr/message header size, or recipient list, exceeds policy limit/,
        qr/message mime complexity exceeds the policy maximum/,
        qr/message refused by mailmarshal spamprofiler/,
        qr/our filters rate at and above .+ percent probability of being spam/,
        qr/rejected: spamassassin score /,
        qr/rejected due to spam content/,   # rejected due to spam
        qr/routing loop detected -- too many received: headers/,
        qr/spambouncer identified spam/,    # SpamBouncer identified SPAM
        qr/the headers in this message contain improperly-formatted binary content/,
        qr/the message was rejected because it contains prohibited virus or spam content/,
        qr/this message contains invalid MIME headers/,
        qr/this message contains improperly-formatted binary content/,
        qr/this message contains text that uses unnecessary base64 encoding/,
        qr/we dont accept spam/,
        qr/your message has been temporarily blocked by our filter/,
    ];
}

1;
__END__
