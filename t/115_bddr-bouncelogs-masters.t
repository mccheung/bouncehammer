# $Id: 115_bddr-bouncelogs-masters.t,v 1.10.2.1 2013/08/30 23:05:12 ak Exp $
#  ____ ____ ____ ____ ____ ____ ____ ____ ____ 
# ||L |||i |||b |||r |||a |||r |||i |||e |||s ||
# ||__|||__|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
use lib qw(./t/lib ./dist/lib ./src/lib);
use strict;
use warnings;
use Kanadzuchi::Test;
use Test::More ( 'tests' => 2864 );

#  ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ 
# ||G |||l |||o |||b |||a |||l |||       |||v |||a |||r |||s ||
# ||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
#
my $Methods = [ 
    'whichtable', 'mastertables', 'new', 'is_validid', 'is_validcolumn',
    'count', 'getidbyname', 'getnamebyid', 'getentbyid', 'search', 'insert',
    'update', 'remove'
];

my $Tables = [ qw/addressers senderdomains destinations hostgroups providers reasons/ ];
my $Master = {};
my $Class = 'Kanadzuchi::BdDR::BounceLogs::Masters::Table';
my $Klass = 'Kanadzuchi::BdDR::BounceLogs::Masters';
my $BdDR = undef;
my $Page = undef;

#  ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ 
# ||T |||e |||s |||t |||       |||c |||o |||d |||e |||s ||
# ||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|
#

SKIP: {
    my $howmanyskips = 2864;
    eval { require DBI; }; skip( 'Because no DBI for testing', $howmanyskips ) if $@;
    eval { require DBD::SQLite; }; skip( 'Because no DBD::SQLite for testing', $howmanyskips ) if $@;

    require Kanadzuchi::Test::DBI;
    require Kanadzuchi::BdDR;
    require Kanadzuchi::BdDR::Page;
    require Kanadzuchi::BdDR::BounceLogs::Masters;

    can_ok( $Class, @$Methods );

    CONNECT: {
        $BdDR = Kanadzuchi::BdDR->new;
        $BdDR->setup( { 'dbname' => ':memory:', 'dbtype' => 'SQLite' } );
        $BdDR->printerror(1);
        $BdDR->connect;

        isa_ok( $BdDR, 'Kanadzuchi::BdDR' );
        isa_ok( $BdDR->handle, 'DBI::db' );
    }

    MASTERTABLE: {
        $Master = $Class->mastertables( $BdDR->handle );
        foreach my $_mt ( @$Tables ) {
            isa_ok( $Master->{ $_mt }, $Class, '('.$_mt.')' );
            isa_ok( $Master->{ $_mt }->{'object'}, $Klass, '('.$_mt.')' );
        }

        $Page = new Kanadzuchi::BdDR::Page;
        $Page->resultsperpage(100);
        isa_ok( $Page, 'Kanadzuchi::BdDR::Page' );
    }

    BUILD_DATABASE: {
        ok( Kanadzuchi::Test::DBI->buildtable( $BdDR->handle ), '->DBI->buildtable' );
    }

    EACH_TABLE: {
        require Kanadzuchi;
        require Kanadzuchi::RFC2822;
        require Kanadzuchi::Time;

        my $tabset = {
            'Addressers' => { 'column' => 'email', 'has' => 'sender01@example.jp', 'new' => 'vicepresident@example.gov' },
            'SenderDomains' => {'column' => 'domainname', 'has' => 'example.jp', 'new' => 'example.gov' },
            'Destinations' => {'column' => 'domainname', 'has' => 'example.org', 'new' => 'example.kyoto.lg.jp' },
            'HostGroups' => { 'column' => 'name', 'has' => 'cellphone', 'new' => 'uucp' },
            'Providers' => { 'column' => 'name', 'has' => 'rfc2606', 'new' => 'ieee' },
            'Reasons' => { 'column' => 'why', 'has' => 'userunknown', 'new' => 'closed' },
        };
        my $R = 39;

        foreach my $tableobject ( keys %$tabset ) {

            my $object = $Master->{ lc $tableobject };
            my $tclass = $object->alias;
            my $thisid = 0;
            my $previd = 0;
            my $myname = q();
            my $entity = {};
            my $nudata = {};
            my $dbdata = [];
            my $sorted = [];
            my $record = 0;
            my $status = 0;

            PREPROCESS: {
                $thisid = 0;
                $myname = q();
                $entity = {};
                $dbdata = [];
                $sorted = [];
                $record = 0;
                $status = 0;

                isa_ok( $object, $Class );
            }

            CONSTRUCTOR: {
                is( $object->table, 't_'.lc( $tclass ), 'object->table = '.'t_'.lc( $tclass ) );
                is( $object->field, $tabset->{ $tclass }->{'column'}, 'object->field = '.$tabset->{ $tclass }->{'column'} );
                is( $object->alias, $tclass, 'object->alias = '.$tclass );
                isa_ok( $object->object, $Klass, 'object->object = '.$Klass );
            }

            EACH_METHOD: {
                GETIDBYNAME: {
                    EXISTS: {
                        $thisid = $object->getidbyname( $tabset->{$tclass}->{'has'} );
                        ok( $thisid, '->getidbyname('.$tabset->{ $tclass }->{'has'}.') = '.$thisid );
                    }

                    FAILS: {
                        is( $object->getidbyname, 0, 'Due to the name is empty, getidbyname failed' );

                        foreach my $e ( @{ $Kanadzuchi::Test::ExceptionalValues } ) {
                            my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                            is( $object->getidbyname( $e ), 0, 'Due to invalid name: '.$argv.', getidbyname failed' );
                        }

                        foreach my $n ( @{ $Kanadzuchi::Test::NegativeValues } ) {
                            is( $object->getidbyname( $n ), 0, 'Due to invalid name: '.$n.', getidbyname failed' );
                        }
                    }
                }

                GETNAMEBYID: {
                    EXISTS: {
                        $myname = $object->getnamebyid($thisid);
                        is( $myname, $tabset->{$tclass}->{'has'}, '->getnamebyid = '.$myname.' by ID '.$thisid );
                    }

                    FAILS: {
                        is( $object->getnamebyid(1e4), q(), 'The name by ID '.1e4.' does not exist' );

                        foreach my $e ( @{ $Kanadzuchi::Test::ExceptionalValues } ) {
                            my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                            is( $object->getnamebyid( $e ), q(),
                                'Due to invalid ID: '.$argv.', getnamebyid failed' );
                        }

                        foreach my $n ( @{ $Kanadzuchi::Test::NegativeValues } ) {
                            is( $object->getnamebyid( $n ), q(),
                                'Due to invalid ID: '.$n.', getnamebyid failed' );
                        }
                    }
                }

                GETENTBYID: {
                    EXISTS: {
                        $entity = $object->getentbyid( $thisid );
                        isa_ok( $entity, 'HASH', '->getentbyid returns entity by ID '.$thisid );
                        is( $entity->{'id'}, $thisid, 'entity->id = '.$entity->{'id'} );
                        is( $entity->{'name'}, $tabset->{$tclass}->{'has'}, 'entity->name = '.$entity->{'name'} );
                        ok( exists $entity->{'description'}, 'entity->description = '.$entity->{'description'} );
                        ok( exists $entity->{'disabled'}, 'entity->disabled = '.$entity->{'disabled'} );
                    }

                    FAILS: {
                        $entity = $object->getentbyid(1e4);
                        is( exists $entity->{'name'}, q(), 'The entity by ID '.1e4.' returns empty hash reference' );

                        $entity = $object->getentbyid;
                        is( exists $entity->{'name'}, q(), 'Due to the ID is empty, getentbyid returns empty hash reference' );

                        foreach my $e ( @{ $Kanadzuchi::Test::ExceptionalValues } ) {
                            my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                            $entity = $object->getentbyid( $e );
                            is( exists $entity->{'name'}, q(), 'Due to invalid ID: '.$argv.', getentbyid returns empty hash reference' );
                        }

                        foreach my $n ( @{ $Kanadzuchi::Test::NegativeValues } ) {
                            $entity = $object->getentbyid( $n );
                            is( exists $entity->{'name'}, q(), 'Due to invalid ID: '.$n.', getentbyid returns empty hash reference' );
                        }
                    }
                }

                SEARCH: {
                    $dbdata = $object->search( {}, $Page );
                    $record = scalar @$dbdata;

                    isa_ok( $dbdata, 'ARRAY', '->seach returns array reference' );
                    ok( $record, '->search return '.$record.' records' );

                    foreach my $d ( @$dbdata ) {
                        isa_ok( $d, 'HASH', 'each entity is hash reference' );
                        ok( $d->{'id'}, qq|->search: ID = $d->{id}, name = $d->{name}| );
                    }

                    ORDER_BY_COLUMN: {

                        foreach my $o ( 'id', $tabset->{ $tclass }->{'column'}, 'description', 'disabled' ) {
                            $previd = 0;
                            $Page->colnameorderby( $o );
                            $sorted = $object->search( {}, $Page );
                            isa_ok( $sorted, 'ARRAY', '->search ORDER BY '.$o.' returns array reference' );
                            is( scalar @$sorted, $record, '->search ORDER BY returns '.$record.' records' );

                            next unless $o eq 'id';
                            ok( eq_set( $sorted, $dbdata ), '->search ORDER BY is equals to the array by ->search' );

                            foreach my $oo ( @$sorted ) {
                                ok( ( $oo->{'id'} > $previd ), 'The ID '.$oo->{'id'}.' is greater than '.$previd );

                            } continue {
                                $previd = $oo->{'id'};
                            }
                        }
                    }

                    WHERE_CONDITION: {
                        $Page->colnameorderby('id');
                        $dbdata = $object->search( { 'id' => 1 }, $Page );
                        $record = scalar @$dbdata;

                        isa_ok( $dbdata, 'ARRAY', '->seach() returns array reference' );
                        ok( $record, '->search() return '.$record.' records' );

                        foreach my $d ( @$dbdata ) {
                            isa_ok( $d, 'HASH', 'each entity is hash reference' );
                            ok( $d->{'id'}, qq|->search(): ID = $d->{id}, name = $d->{name}| );
                        }
                    }

                }

                INSERT: {
                    $nudata = { 
                        'name' => $tabset->{ $tclass }->{'new'},
                        'description' => ucfirst $tabset->{ $tclass }->{'new'},
                        'disabled' => 0,
                    };
                    $thisid = $object->insert( $nudata );
                    ok( $thisid, '->insert() new record: ID = '.$thisid.', name = '.$nudata->{'name'} );
                    $entity = $object->getentbyid( $thisid );
                    $nudata->{'id'} = $thisid;

                    is( $entity->{'name'}, lc $nudata->{'description'}, '->name == ->description ' );
                    is( $entity->{'description'}, ucfirst $entity->{'name'}, '->name == ->description ' );
                    is( $entity->{'disabled'}, 0, '->disabled = 0' );
                    is( $object->getnamebyid( $entity->{'id'} ), $entity->{'name'}, 'SELECT(getnamebyid()) again = '.$entity->{'name'} );

                    foreach my $e ( 
                        @{ $Kanadzuchi::Test::EscapeCharacters },
                        @{ $Kanadzuchi::Test::ControlCharacters } ) {

                        my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                        is( $object->insert( {' name' => $e } ), 0, 
                            '->insert() Cannot INSERT new record by the name: '.$argv );
                    }

                    is( $object->insert, 0, 'Due to no db object, ->insert() returns 0: failed' );
                }

                UPDATE: {
                    $nudata->{'description'} = 'test';
                    $nudata->{'disabled'} = 1;
                    $status = $object->update( $nudata, { 'id' => $nudata->{'id'} } );
                    $entity = $object->getentbyid( $nudata->{'id'} );

                    ok( $status, qq|->update($status): desc = test disabled() = 1| );
                    is( $entity->{'description'}, 'test', '->getentbyid() again(description)' );
                    is( $entity->{'disabled'}, 1, '->getentbyid() again(disabled)' );

                    foreach my $e ( @{ $Kanadzuchi::Test::ExceptionalValues } ) {
                        my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                        is( $object->update( $e ), 0, '->update failed for invalid ID '.$argv );
                    }

                    foreach my $n ( @{ $Kanadzuchi::Test::NegativeValues } ) {
                        is( $object->update( $n ), 0, '->update failed for invalid ID '.$n );
                    }

                    is( $object->update, 0, 'Due to no db object, ->update() returns 0: failed' );
                }


                DELETE: {
                    $status = $object->remove( { 'id' => $thisid } );
                    ok( $status, '->remove(), ID = '.$thisid );

                    $entity = $object->getentbyid( $thisid );
                    is( exists $entity->{'id'}, q(), 'ID '.$thisid.' does not exist on the database' );

                    foreach my $e ( @{ $Kanadzuchi::Test::ExceptionalValues } ) {
                        my $argv = defined $e ? sprintf( "%#x", ord $e ) : 'undef';
                        is( $object->remove( $e ), 0, '->remove failed for invalid ID '.$argv );
                    }

                    foreach my $n ( @{ $Kanadzuchi::Test::NegativeValues } ) {
                        is( $object->remove( $n ), 0, '->remove() failed for invalid ID '.$n );
                    }

                    is( $object->remove, 0, 'Due to no db object, ->remove() returns 0: failed' );
                }
            }

        } # End of foreach()
    }
}

__END__
