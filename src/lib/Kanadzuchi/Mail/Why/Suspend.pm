# $Id: Suspend.pm,v 1.1.2.2 2013/08/28 10:05:32 ak Exp $
# Copyright (C) 2013 Cubicroot Co. Ltd.
# Kanadzuchi::Mail::Why::
                                                    
  #####                                         ##  
 ###     ##  ##  ##### #####   ####  #####      ##  
  ###    ##  ## ##     ##  ## ##  ## ##  ##  #####  
   ###   ##  ##  ####  ##  ## ###### ##  ## ##  ##  
    ###  ##  ##     ## #####  ##     ##  ## ##  ##  
 #####    ##### #####  ##      ####  ##  ##  #####  
                       ##                           
package Kanadzuchi::Mail::Why::Suspend;
use base 'Kanadzuchi::Mail::Why';

#  ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
# ||C |||l |||a |||s |||s |||       |||M |||e |||t |||h |||o |||d |||s ||
# ||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
# Regular expressions of 'Suspend'
sub exemplaria {
    my $class = shift;
    return [
        qr/recipient suspend the service/,
        qr/sorry your message to .+ cannot be delivered[.] this account has been disabled or discontinued/,
    ];
}

1;
__END__
