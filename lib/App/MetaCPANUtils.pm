package App::MetaCPANUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

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
    },
};
sub list_recent_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;
    my $recent = $mcpan->recent($args{n});
    my @rows;
    while (my $rel = $recent->next) {
        push @rows, {
            release      => $rel->name,
            date         => $rel->date,
            author       => $rel->author,
            maturity     => $rel->maturity,
            version      => $rel->version,
            distribution => $rel->distribution,
            abstract     => $rel->abstract,
        };
    }

    [200, "OK", \@rows];
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
