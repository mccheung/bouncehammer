# $Id: Cellphone.pm,v 1.1.2.4 2013/08/30 08:51:14 ak Exp $
# Copyright (C) 2009-2010,2013 Cubicroot Co. Ltd.
# Kanadzuchi::Mail::Group::UK::
                                                            
  ####        ###  ###         ##                           
 ##  ##  ####  ##   ##  #####  ##      ####  #####   ####   
 ##     ##  ## ##   ##  ##  ## #####  ##  ## ##  ## ##  ##  
 ##     ###### ##   ##  ##  ## ##  ## ##  ## ##  ## ######  
 ##  ## ##     ##   ##  #####  ##  ## ##  ## ##  ## ##      
  ####   #### #### #### ##     ##  ##  ####  ##  ##  ####   
                        ##                                  
package Kanadzuchi::Mail::Group::UK::Cellphone;
use base 'Kanadzuchi::Mail::Group';
use strict;
use warnings;

#  ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
# ||C |||l |||a |||s |||s |||       |||M |||e |||t |||h |||o |||d |||s ||
# ||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
# Cellular phone domains in The United Kingdom
# See http://en.wikipedia.org/wiki/List_of_SMS_gateways
# sub communisexemplar { return qr{[.]uk\z}; }
sub nominisexemplaria {
    # *** NOT TESTED YET ***
    my $self = shift;
    return {
        '24x' => [
            # http://www.24x.com
            qr{\A24xgateway[.]com\z},
        ],
        'aql' => [
            # aql; http://aql.com/
            qr{\Atext[.]aql[.]com\z},   # http://aql.com/sms/email-to-sms/
        ],
        'csoft' => [
            # Connection Software; https://www.csoft.co.uk
            qr{\Aitsarrived[.]net\z},
        ],
        'esendex' => [
            # Esendex; http://www.esendex.co.uk
            qr{\Aechoemail[.]net\z},
        ],
        'haysystems' => [
            # Hay Systems Ltd (HSL); http://www.haysystems.com/mobile-networks/hsl-femtocell/
            qr{\Asms[.]haysystems[.]com\z},
        ],
        'mediaburst' => [
            # Mediaburst; http://www.mediaburst.co.uk
            qr{\Asms[.]mediaburst[.]co[.]uk\z},
        ],
        'mycoolsms' => [
            # My-Cool-SMS
            qr{\Amy-cool-sms[.]com\z},
        ],
        'o2' => [
            # O2 (officially Telef坦nica O2 UK) ; http://www.o2.co.uk/
            qr{\Amobile[.]celloneusa[.]com\z},  # 44number@
            qr{\Ammail[.]co[.]uk\z},
            qr{\Ao2imail[.]co[.]uk\z},      # Cannot resolve ARR, MXRR
        ],
        'orange' => [
            # Orange U.K.; http://www.orange.co.uk/
            qr{\Aorange[.]net\z},       # 0number@
        ],
        't-mobile' => [
            # T-Mobile; http://www.t-mobile.net/
            qr{\At-mobile[.]uk[.]net\z},
        ],
        'txtlocal' => [
            # Txtlocal; http://www.txtlocal.co.uk/
            qr{\Atxtlocal[.]co[.]uk\z},
        ],
        'unimovil' => [
            # UniMóvil Corporation
            qr{\Aviawebsms[.]com\z},
        ],
        'virgin' => [
            # Virgin Mobile; http://www.virginmobile.com/
            qr{\Avxtras[.]com\z},
        ],
        'vodafone' => [
            # Vodafone; http://www.vodafone.com/
            qr{\Avodafone[.]net\z},
        ],
    };
}

1;
__END__
