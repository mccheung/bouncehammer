# $Id: Makefile.am,v 1.4.2.3 2013/07/17 04:12:24 ak Exp $
# Copyright (C) 2009,2010 Cubicroot Co. Ltd.
# This is the auto-Makefile for bounceHammer/src/lib/Kanadzuchi/Mail/Why,
# is processed by automake to create Makefile.in.

distdir = $(BUILDROOT)/dist/lib/Kanadzuchi/Mail/Why
pkgdatadir = @libdir@/Kanadzuchi/Mail/Why
pkgdata_DATA = ExceedLimit.pm Filtered.pm HostUnknown.pm MailboxFull.pm \
		RelayingDenied.pm SystemFull.pm MesgTooBig.pm \
		UserUnknown.pm Rejected.pm Suspend.pm SecurityError.pm \
		SystemError.pm ContentError.pm NotAccept.pm \
		MailerError.pm Expired.pm

all-am:
	test -d $(distdir) || mkdir -p $(distdir)
	cp -Rp $(pkgdata_DATA) $(distdir)/

.PHONY: clean
clean:
	rm -f $(distdir)/*.pm

