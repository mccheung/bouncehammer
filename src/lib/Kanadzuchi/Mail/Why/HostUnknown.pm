# $Id: HostUnknown.pm,v 1.9.2.3 2013/08/30 05:55:25 ak Exp $
# -Id: HostUnknown.pm,v 1.1 2009/08/29 07:33:28 ak Exp -
# -Id: HostUnknown.pm,v 1.1 2009/05/04 05:17:05 ak Exp -
# Copyright (C) 2009,2010,2013 Cubicroot Co. Ltd.
# Kanadzuchi::Mail::Why::
                                                                                
 ##  ##                 ##   ##  ##         ##                                  
 ##  ##  ####   ##### ###### ##  ##  #####  ##     #####   ####  ##  ## #####   
 ###### ##  ## ##       ##   ##  ##  ##  ## ## ##  ##  ## ##  ## ##  ## ##  ##  
 ##  ## ##  ##  ####    ##   ##  ##  ##  ## ####   ##  ## ##  ## ###### ##  ##  
 ##  ## ##  ##     ##   ##   ##  ##  ##  ## ## ##  ##  ## ##  ## ###### ##  ##  
 ##  ##  ####  #####     ###  ####   ##  ## ##  ## ##  ##  ####  ##  ## ##  ##  
package Kanadzuchi::Mail::Why::HostUnknown;
use base 'Kanadzuchi::Mail::Why';

#  ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
# ||C |||l |||a |||s |||s |||       |||M |||e |||t |||h |||o |||d |||s ||
# ||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
# Regular expressions of 'Host Unknown'
sub exemplaria {
    my $class = shift;
    return [
        qr/recipient domain must exist/,    # qmail ?
        qr/host or domain name not found/,
        qr/host unknown/,
        qr/host unreachable/,
        qr/name or service not known/,
        qr/no such domain/,
        qr/recipient address rejected: unknown domain name/,
    ];
}

1;
__END__
