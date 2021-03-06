#__PERLEXECUTABLE__
# $Id: tablectl.PL,v 1.16.2.9 2013/08/30 05:56:47 ak Exp $
# -Id: tablectl.PL,v 1.12 2010/02/21 20:09:01 ak Exp -
# -Id: tablectl.PL,v 1.1 2009/08/29 14:36:53 ak Exp -
# -Id: tablectl.PL,v 1.9 2009/08/27 05:09:59 ak Exp -
# Copyright (C) 2009-2011,2013 Cubicroot Co. Ltd.
# Kanadzuchi::Command::
                                                    
   ##         ##    ###                 ##   ###    
 ###### ####  ##     ##   ####   #### ######  ##    
   ##      ## #####  ##  ##  ## ##      ##    ##    
   ##   ##### ##  ## ##  ###### ##      ##    ##    
   ##  ##  ## ##  ## ##  ##     ##      ##    ##    
    ### ##### ##### ####  ####   ####    ### ####   
package Kanadzuchi::Command::Tablectl;

#  ____ ____ ____ ____ ____ ____ ____ ____ ____ 
# ||L |||i |||b |||r |||a |||r |||i |||e |||s ||
# ||__|||__|||__|||__|||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
#
use lib '__KANADZUCHIROOT__/lib';
use lib '__PERLEXTERNALLIB__';
use strict;
use warnings;
use Kanadzuchi;
use Kanadzuchi::UI::CLI;
use Kanadzuchi::BdDR;
use Kanadzuchi::BdDR::Page;
use Kanadzuchi::BdDR::BounceLogs::Masters;
use Error ':try';

#  ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ 
# ||G |||l |||o |||b |||a |||l |||       |||v |||a |||r |||s ||
# ||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
#
my $bHb;            # (Kanadzuchi) System object
my $Cmd;            # (Kanadzuchi::UI::CLI) Commandline object
my $Rdb;            # (Kanadzuchi::BdDR) Database object
my $Tab;            # (Kanadzuchi::BdDR::BounceLogs::Masters::Table)
my $Fmt;            # (String) Output fotmat
my $Alias = q();    # (String) Table alias
my $Wcond = {};     # (Ref->Hash) Where condition

my $CLIOPTION = {
    'conf'      => ( 1 << 0 ),
    'test'      => ( 1 << 1 ),
    'database'  => ( 1 << 2 ),
    'list'      => ( 1 << 3 ),
    'insert'    => ( 1 << 4 ),
    'remove'    => ( 1 << 5 ),
    'update'    => ( 1 << 6 ),
    'modify'    => ( 1 << 7 ),
};


#  __  __    _    ___ _   _ 
# |  \/  |  / \  |_ _| \ | |
# | |\/| | / _ \  | ||  \| |
# | |  | |/ ___ \ | || |\  |
# |_|  |_/_/   \_\___|_| \_|
#
# Create Kanadzuchi object
$bHb = new Kanadzuchi;
$Cmd = new Kanadzuchi::UI::CLI(
        'option' => $CLIOPTION,
        'commandline' => join( ' ', $0, @ARGV )
);

# Create Kanadzuchi::BdDR object
$Rdb = new Kanadzuchi::BdDR;

# Parse options, initialize object
try {
    if( $Cmd->operation( parse_options() ) == 0 ) {
        Kanadzuchi::Exception::Command->throw( '-text' => 'Try --help' );
    }

    my $_load = $bHb->load( $Cmd->cf );
    if( Kanadzuchi->is_exception( $_load ) ) {
        Kanadzuchi::Exception::System->throw( '-text' => $_load );
    }

    $Cmd->init( $bHb );
    $Cmd->d( 1, sprintf( "Config file = %s\n", $Cmd->cf ));

    if( ( $Cmd->operation & $Cmd->option->{'modify'} ) && $bHb->config->{'syslog'}->{'enabled'} ) {

        $Cmd->d( 2, sprintf("Syslog facility = %s\n", $bHb->config->{'syslog'}->{'facility'} ));
        $bHb->historique( 'info', 'stat=starting (version '.$bHb->version.')' );
    }

} otherwise {
    my $e = shift;
    $Cmd->exception( $e );
    $bHb->historique( 'err', 'stat='.$e ) if ( $Cmd->operation & $Cmd->option->{'modify'} );
    $Cmd->abort;
};


# Set signal handlers
foreach my $sig ( 'INT','QUIT','TERM','KILL','ALRM' ) {
    $SIG{ $sig } = sub { $Cmd->catch_signal( $sig ); };
}

if( $Cmd->operation & $Cmd->option->{'database'} ) {
    #  _   _ ____  _____   ____  ____  
    # | | | / ___|| ____| |  _ \| __ ) 
    # | | | \___ \|  _|   | | | |  _ \ 
    # | |_| |___) | |___  | |_| | |_) |
    #  \___/|____/|_____| |____/|____/ 
    #
    try {
        Kanadzuchi::Exception::Command->throw( '-text' => 'No table name' ) unless $Alias;

        $Rdb->setup( $bHb->config->{'database'} );
        Kanadzuchi::Exception::Database->throw(
                '-text' => 'Failed to connect DB' ) unless $Rdb->connect;
        $Cmd->d(2,"Connecting to the database\n") if defined $Rdb->handle;

        # Create master table object(Tab)
        $Tab = new Kanadzuchi::BdDR::BounceLogs::Masters::Table( 'alias' => $Alias, 'handle' => $Rdb->handle );
        Kanadzuchi::Exception::Database->throw( '-text' => 'No such table' ) unless defined $Tab;

        ( $Rdb->hostname ne 'localhost' && $Rdb->port ne q() )
            ? $Cmd->d( 2, sprintf( "Database host = %s:%s\n", $Rdb->hostname, $Rdb->port ) )
            : $Rdb->hostname eq 'localhost'
                ? $Cmd->d( 2, 'Database host = Socket'.qq{\n}) 
                : 1;

        $Cmd->d( 2, sprintf( "Database name = %s(%s)\n", $Rdb->dbname, $Rdb->dbtype ) );
        $Cmd->d( 2, sprintf( "Database user = %s\n", $Rdb->username ) );
        $Cmd->d( 2, sprintf( "Using table = %s\n", $Tab->alias ) );

    } otherwise {
        my $e = shift;
        my $b = '-' x 64;
        my $m = $e;

        if( length $Rdb->error->{'string'} ) {

            $m .= "\n".$b;
            $m .= "\n ".$Rdb->error->{'string'};
            $m .= $b;
            $m .= "\n";
            $e .= ': '.$Rdb->error->{'string'};
        }
        $Cmd->exception( $m );
        $bHb->historique( 'err', 'stat='.$e );
        $Cmd->abort;
    };

    if( $Cmd->operation & $Cmd->option->{'list'} ) {
        #  ____  _____ _     _____ ____ _____   _     ___ ____ _____ 
        # / ___|| ____| |   | ____/ ___|_   _| | |   |_ _/ ___|_   _|
        # \___ \|  _| | |   |  _|| |     | |   | |    | |\___ \ | |  
        #  ___) | |___| |___| |__| |___  | |_  | |___ | | ___) || |  
        # |____/|_____|_____|_____\____| |_( ) |_____|___|____/ |_|  
        #                                  |/
        my $pagination;                 # (Kanadzuchi::Page) Pagination object
        my $selectedrs;                 # (Ref->Hash) Searched entries
        my $asciitable;                 # (Text::ASCIITable) ASCII Table object
        my $columnname = $Tab->field;   # (String) Fieldname in the table

        # Avoid the error ``character in print at..''
        binmode( STDOUT, ':utf8' );

        # Check output format
        if( $Fmt eq 'asciitable' ) {
            # Human readable ASCII table
            require Text::ASCIITable;
            $asciitable = new Text::ASCIITable( { 'headingText' => $Tab->alias } );
            $asciitable->setOptions( 'outputWidth', 80 );
            $asciitable->setCols( '#ID', $columnname, 'description', 'disabled' );
        }

        # Make Pagination object
        $pagination = new Kanadzuchi::BdDR::Page;
        $pagination->set( $Tab->count( $Wcond ) );

        MESSAGE_IN_VERBOSE_MODE: {
            last unless $Cmd->debuglevel;
            map { $Cmd->d( 2, sprintf( "Find by %s = %s\n", $_, $Wcond->{ $_ } ) ) } keys %$Wcond;
            $Cmd->d( 3, sprintf( "SELECT * FROM %s;\n", $Tab->alias ) ) unless keys %$Wcond;
        }

        $Cmd->d( 2, 'SELECT'."\n" );

        RETRIEVE_THE_RESULTS: while(1) {
            $selectedrs = $Tab->search( $Wcond, $pagination );

            PRINT_THE_LIST: while( my $r = shift @$selectedrs ) {

                if( defined $asciitable ) {
                    $asciitable->addRow( $r->{'id'}, $r->{'name'}, $r->{'description'}, $r->{'disabled'} );

                } else {
                    # YAML
                    printf( STDOUT qq|- { "id": %d, "%s": "%s", "description": "%s", "disabled": %d }\n|,
                        $r->{'id'}, $columnname, $r->{'name'}, $r->{'description'}, $r->{'disabled'} );
                }
            } # End of while(PRINT_THE_LIST)

            last unless $pagination->hasnext;
            $pagination->next;

        } # End of while(RETRIEVE_THE_RESULTS)

        if( defined $asciitable && scalar @{ $asciitable->{'tbl_rows'} } ) {

            $asciitable->addRowLine;
            printf( STDOUT "%s", $asciitable->draw );
        }

    } elsif( $Cmd->operation & $Cmd->option->{'modify'} ) {
        #  __  __  ___  ____ ___ _______   __
        # |  \/  |/ _ \|  _ \_ _|  ___\ \ / /
        # | |\/| | | | | | | | || |_   \ V / 
        # | |  | | |_| | |_| | ||  _|   | |  
        # |_|  |_|\___/|____/___|_|     |_|  
        #
        my $ismodified = 0;     # Flag, 1 = modified, 0 = failed
        my $newelement = {};    # (Ref->Hash) New data

        if( $Cmd->operation & $Cmd->option->{'update'} ) {
            #  _   _ ____  ____    _  _____ _____ 
            # | | | |  _ \|  _ \  / \|_   _| ____|
            # | | | | |_) | | | |/ _ \ | | |  _|  
            # | |_| |  __/| |_| / ___ \| | | |___ 
            #  \___/|_|   |____/_/   \_\_| |_____|
            # 
            try {
                # ID is not given , ID:0 is not valid
                Kanadzuchi::Exception::Command->throw( 
                    '-text' => 'No or invalid ID' ) unless $Wcond->{'id'};

                if( ! exists( $Wcond->{'name'} ) &&
                    ! exists( $Wcond->{'description'} ) &&
                    ! exists( $Wcond->{'disabled'} ) ) {

                    Kanadzuchi::Exception::Command->throw( '-text' =>
                        'There are neither --name, --discription nor --disabled' );

                } elsif( exists $Wcond->{'name'} && length( $Wcond->{'name'} ) == 0 ) {

                    Kanadzuchi::Exception::Command->throw( 
                        '-text' => 'The argument of --name is empty !' );
                }

                map { $newelement->{ $_ } = $Wcond->{ $_ } if( exists $Wcond->{ $_ } ) } ( qw/name description disabled/ )

            } catch Kanadzuchi::Exception::Command with {

                my $e = shift;
                $Cmd->exception( $e );
                $bHb->historique( 'err', 'mode=update, stat='.$e );
                $Cmd->abort;
            };

            # UPDATE
            $Cmd->d( 2, 'UPDATE'."\n" );
            $ismodified = $Tab->update( $newelement, { 'id' => $Wcond->{'id'} } );

            if( $ismodified ) {
                $Cmd->d( 2, 'Successfully updated ( ID = '.$Wcond->{'id'}." )\n" );
                $bHb->historique( 'info', 
                    sprintf( "updated=1, id=%d, mode=update, stat=ok",$Wcond->{'id'} ) );

            } else {
                $Cmd->d( 2, "Failed to UPDATE\n" );
                $bHb->historique( 'err', 
                    sprintf( "updated=0, id=%d, mode=update, stat=failed", $Wcond->{'id'} ) );
            }

        } elsif( $Cmd->operation & $Cmd->option->{'remove'} ) {
            #  ____  _____ _     _____ _____ _____ 
            # |  _ \| ____| |   | ____|_   _| ____|
            # | | | |  _| | |   |  _|   | | |  _|  
            # | |_| | |___| |___| |___  | | | |___ 
            # |____/|_____|_____|_____| |_| |_____|
            #
            try {
                # ID is not given , ID:0 is not valid
                Kanadzuchi::Exception::Command->throw( '-text' => 'No or invalid ID' ) unless $Wcond->{'id'};

            } catch Kanadzuchi::Exception::Command with {
                my $e = shift;
                $Cmd->exception( $e );
                $bHb->historieque( 'err',$e.', mode=remove' );
                $Cmd->abort;
            };

            # DELETE FROM...
            $Cmd->d( 2, 'DELETE'."\n" );
            $ismodified = $Tab->remove( { 'id' => $Wcond->{'id'} } );

            if( $ismodified ) {
                $Cmd->d( 2, 'Successfully deleted ( ID = '.$Wcond->{'id'}." )\n" );
                $bHb->historique( 'info', 
                    sprintf( "removed=1, id=%d, mode=remove, stat=ok",$Wcond->{'id'} ) );

            } else {
                $Cmd->d( 2, "Failed to DELETE\n" );
                $bHb->historique( 'err', 
                    sprintf( "removed=0, id=%d, mode=remove, stat=failed", $Wcond->{'id'} ) );
            }

        } elsif( $Cmd->operation & $Cmd->option->{'insert'} ) {
            #  ___ _   _ ____  _____ ____ _____ 
            # |_ _| \ | / ___|| ____|  _ \_   _|
            #  | ||  \| \___ \|  _| | |_) || |  
            #  | || |\  |___) | |___|  _ < | |  
            # |___|_| \_|____/|_____|_| \_\|_|  
            #
            try {
                if( ! exists $Wcond->{'name'} ) {
                    Kanadzuchi::Exception::Command->throw( 
                        '-text' => 'There are no name with --name option' );
                }

                map { $newelement->{ $_ } = $Wcond->{ $_ } if exists $Wcond->{ $_ } } ( qw/name description disabled/ )

            } catch Kanadzuchi::Exception::Command with {
                my $e = shift;
                $Cmd->exception( $e );
                $bHb->historique( 'err', 'mode=insert, stat='.$e );
                $Cmd->abort;
            };

            # INSERT INTO...
            $Cmd->d( 2, 'INSERT'."\n" );
            $ismodified = $Tab->insert( $newelement );

            if( $ismodified ) {

                $Cmd->d( 2, 'Successfully inserted ( ID = '.$ismodified." )\n" );
                $bHb->historique( 'info', 
                    sprintf( "inserted=1, id=%d, name=%s, mode=insert, stat=ok",
                            $ismodified, $newelement->{'name'} )
                );

            } else {
                $Cmd->d( 2, 'Failed to INSERT'."\n" );
                $bHb->historique( 'err', 
                    sprintf( "inserted=0, id=?, name=%s, mode=insert,stat=failed",
                        $newelement->{'name'} )
                );
            }
        }
    }
}

$Cmd->finish;


#  _____ _   _ _   _  ____ _____ ___ ___  _   _ ____  
# |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | / ___| 
# | |_  | | | |  \| | |     | |  | | | | |  \| \___ \ 
# |  _| | |_| | |\  | |___  | |  | | |_| | |\  |___) |
# |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|____/ 
# 
sub parse_options
{ 
    # +-+-+-+-+-+-+-+-+-+-+-+-+-+
    # |p|a|r|s|e|_|o|p|t|i|o|n|s|
    # +-+-+-+-+-+-+-+-+-+-+-+-+-+
    #
    # @Description  Parse given options, and set the operation mode.
    # @Param        None
    # @Return       n = Integer: operation value(24bit integer)

    require Getopt::Long;
    my $operation = 0;

    # Variables for decide operation
    my (
        $opt_conf,
        $opt_description,
        $opt_disabled,
        $opt_format,
        $opt_host,
        $opt_id,
        $opt_insert,
        $opt_list,
        $opt_name,
        $opt_port,
        $opt_remove,
        $opt_table,
        $opt_test,
        $opt_type,
        $opt_update,
        $opt_database,
        $opt_verbose,
    );

    # Relations of the option name and the option value
    Getopt::Long::Configure( 'bundling', 'no_ignore_case' ); 
    Getopt::Long::GetOptions(
            'conf=s'    => \$opt_conf,
            'C=s'       => \$opt_conf,
            'test'      => \$opt_test,
            'T'         => \$opt_test,
            'help'      => sub { help(); exit(0); },
            'silent'    => sub { $Cmd->silent(1); },
            'verbose'   => \$opt_verbose,
            'v+'        => \$opt_verbose,
            'version'   => sub { printf(STDERR "%s\n", $bHb->version); exit(0); },

            # Output options
            'format=s'  => \$opt_format,
            'F=s'       => \$opt_format,
            'list'      => \$opt_list,

            # Database options
            'insert'    => \$opt_insert,
            'remove'    => \$opt_remove,
            'update'    => \$opt_update,
            'host=s'    => \$opt_host,
            'port=i'    => \$opt_port,
            'type=s'    => \$opt_type,

            # Table and column options
            't=s'       => \$opt_table,
            'table=s'   => \$opt_table,
            'id=i'      => \$opt_id,
            'name=s'    => \$opt_name,
            'description=s' => \$opt_description,
            'disabled=i'    => \$opt_disabled,

        );


    # (verbose|debug) mode
    $Cmd->debuglevel( ( $opt_verbose ? $opt_verbose : 0 ) - 1 );

    # Specify Config File(YAML)
    if( defined $opt_conf ) {
        # Use specified config file(YAML)
        $operation |= $Cmd->option->{'conf'};
        $Cmd->cf( new Path::Class::File($opt_conf) );

    } elsif( $opt_test ) {
        # Test mode,
        $operation |= $Cmd->option->{'test'};
        $Cmd->cf( new Path::Class::File('/dev/null'));

    } else {
        # Use default config file(YAML)
        $Cmd->cf( new Path::Class::File( $Kanadzuchi::SYSCONF )->absolute );
        $Cmd->cf->cleanup;
    }

    # Table control
    if( $opt_list ) {
        $operation |= $Cmd->option->{'database'}; 
        $operation |= $Cmd->option->{'list'};

    } elsif( $opt_update ) {
        $operation |= $Cmd->option->{'database'}; 
        $operation |= $Cmd->option->{'modify'}; 
        $operation |= $Cmd->option->{'update'};

    } elsif( $opt_insert ) {
        $operation |= $Cmd->option->{'database'}; 
        $operation |= $Cmd->option->{'modify'}; 
        $operation |= $Cmd->option->{'insert'};

    } elsif( $opt_remove ) {
        $operation |= $Cmd->option->{'database'}; 
        $operation |= $Cmd->option->{'modify'}; 
        $operation |= $Cmd->option->{'remove'};
    }

    # Select a table
    $Alias = lc( substr( $opt_table,0,1 ) ) if $opt_table;
    $Alias = 'w' if $Alias eq 'r';

    # Field, Column options
    if( $opt_id               ){ $Wcond->{'id'} = int($opt_id); }
    if( $opt_name             ){ $Wcond->{'name'} = $opt_name; }
    if( $opt_description      ){ $Wcond->{'description'} = $opt_description; }
    if( defined $opt_disabled ){ $Wcond->{'disabled'} = $opt_disabled ; }

    # Database spec option, Override values in the config file
    $Rdb->hostname( $opt_host ) if $opt_host;
    $Rdb->dbtype( $opt_type ) if $opt_type;
    $Rdb->port( $opt_port ) if $opt_port;

    if( $opt_format ) {
        if(    substr( $opt_format, 0, 1 ) eq 'y' ){ $Fmt = 'yaml'; }
        elsif( substr( $opt_format, 0, 1 ) eq 'a' ){ $Fmt = 'asciitable'; }
        else { $Fmt = 'yaml'; }

    } else {
        # Default Log format is 'YAML' -Fy
        $Fmt = 'yaml';
    }
    # Check whether or not Required options are specified.
    return $operation;
}

sub help {
    # +-+-+-+-+
    # |h|e|l|p|
    # +-+-+-+-+
    #
    # @Description  Print help messages
    # @Param        NONE
    # @Return       1
    printf( STDERR "%s/%s %s\n", $bHb->myname, $Cmd->calledfrom, $bHb->version );
    printf( STDERR "Usage: %s [OPTIONS] -t<x>\n", $Cmd->calledfrom );
    printf( STDERR "\n" );
    printf( STDERR " * TABLE CONTROL OPTIONS\n" );
    printf( STDERR "    -t, --table <t>       : Table name, ALWAYS REQUIRED.\n");
    printf( STDERR "                            a = [A]ddressers, s = [S]enderDomains, d = [D]estinations\n");
    printf( STDERR "                            h = [H]ostgroups, p = [P]roviders, r,w = [R]easons([w]hy)\n");
    printf( STDERR "    --list                : Print the table contents as a list.\n");
    printf( STDERR "    --update              : UPDATE specified records\n");
    printf( STDERR "    --insert              : INSERT a new record\n");
    printf( STDERR "    --remove              : DELETE a specified record\n");
    printf( STDERR "\n" );
    printf( STDERR " * TABLE COLUMN OPTIONS\n" );
    printf( STDERR "    --id <n>              : ID(>0), this option is required by --update, --remove option.\n");
    printf( STDERR "    --name <str>          : Name, this option is required by --insert option.\n");
    printf( STDERR "    --description <descr> : A value of description field of the record to UPDATE or INSERT.\n");
    printf( STDERR "    --disabled <0|1>      : A value of disabled field, 0 = Turn on, 1 = Turn off\n");
    printf( STDERR "\n" );
    printf( STDERR " * DATABASE SPEC OPTIONS(Overrides the value in the config file)\n" );
    printf( STDERR "    --type <d>            : DB Type, p:Postgres, m:MySQL, s=SQLite .\n");
    printf( STDERR "    --host <hostname>     : DB Host name or IP address\n");
    printf( STDERR "    --port <portnum>      : DB Host port number\n");
    printf( STDERR "\n" );
    printf( STDERR " * OTHER OPTIONS\n" );
    printf( STDERR "    -C, --conf <config>   : Location of the configuration file used instead of \n");
    printf( STDERR "                            __KANADZUCHIETC__/bouncehammer.cf\n");
    printf( STDERR "    -T, --test            : Test mode, same as ``-C /path/to/test-run.cf''\n");
    printf( STDERR "    -F, --format <f>      : Format of the results of --list option,\n");
    printf( STDERR "                            y = YAML, a = ASCIITable.\n");
    printf( STDERR "    --silent              : Silent mode, All MESSAGES WILL NOT BE DISPLAYED.\n");
    printf( STDERR "    -v, --verbose         : Run in verbose mode, -vv is more verbose, -vvv is more.\n");
    printf( STDERR "    --help                : Print help message(This screen)\n");
    printf( STDERR "    --version             : Print version number.\n");
    printf( STDERR "\n" );
    printf( STDERR " * Examples\n" );
    printf( STDERR "  %s -C./test-run.cf -Tw --list -Fa\n", $Cmd->calledfrom );
    printf( STDERR "  %s -ts --insert --name 'example.jp' --discription 'Ex' -v\n", $Cmd->calledfrom );
    printf( STDERR "  %s -ts --update --id 2 --discription 'My Domain'\n", $Cmd->calledfrom );
    printf( STDERR "\n" );
    return 1;
}


__END__
