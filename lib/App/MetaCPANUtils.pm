package App::MetaCPANUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our $release_fields = [qw/
                             release
                             date
                             author
                             maturity
                             version
                             distribution
                             abstract
/];
our %argopt_release_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>$release_fields]],
        default => $release_fields,
        cmdline_aliases=>{f=>{}},
        tags => ['category:filtering'],
    },
);

sub _resultset_to_envres {
    my ($resultset, $wanted_fields) = @_;

    my @rows;
    my $resmeta = {'table.fields' => $wanted_fields};
    while (my $obj = $resultset->next) {
        my $row = {};
        if (ref $obj eq 'MetaCPAN::Client::Release') {
            $row->{release}      = $obj->name         if grep {$_ eq 'release'}      @$wanted_fields;
            $row->{date}         = $obj->date         if grep {$_ eq 'date'}         @$wanted_fields;
            $row->{author}       = $obj->author       if grep {$_ eq 'author'}       @$wanted_fields;
            $row->{maturity}     = $obj->maturity     if grep {$_ eq 'maturity'}     @$wanted_fields;
            $row->{version}      = $obj->version      if grep {$_ eq 'version'}      @$wanted_fields;
            $row->{distribution} = $obj->distribution if grep {$_ eq 'distribution'} @$wanted_fields;
            $row->{abstract}     = $obj->abstract     if grep {$_ eq 'abstract'}     @$wanted_fields;
        } else {
            die "Can't handle result $obj";
        }
        push @rows, $row;
    }
    [200, "OK", \@rows, $resmeta];
}

$SPEC{list_recent_metacpan_releases} = {
    v => 1.1,
    args => {
        n => {
            schema => 'posint*',
            ## no longer true, will list several days' worth nowadays
#            description => <<'_',
#
#If not specified, will list all releases from today.
#
#_
            pos => 0,
        },
        %argopt_release_fields,
    },
};
sub list_recent_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;
    my $recent = $mcpan->recent($args{n});
    _resultset_to_envres($recent, $args{fields});
}

1;
# ABSTRACT: CLI utilities related to MetaCPAN

=head1 DESCRIPTION

This distribution contains CLI utilities related to MetaCPAN:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<https://metacpan.org>

Other distributions providing CLIs for MetaCPAN: L<MetaCPAN::Clients>,
L<App::metacpansearch>.

MetaCPAN API Client: L<MetaCPAN::Client>
