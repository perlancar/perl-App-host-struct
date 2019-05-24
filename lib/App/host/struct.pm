package App::host::struct;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options 'system', -log=>1;
use List::Util qw(uniqstr);

our %SPEC;

$SPEC{host_struct} = {
    v => 1.1,
    summary => 'host alternative that returns data structure',
    args => {
        action => {
            schema  => ['str*', in=>[
                'resolve',
                'resolve-ns-address',
                'resolve-mx-address',
            ]],
            default => 'resolve',
        },
        type => {
            schema => 'str*',
            cmdline_aliases => {t=>{}},
        },
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        server => {
            schema => 'str*',
            pos => 1,
        },
    },
    examples => [
    ],
    description => <<'_',

Early release.

_
};
sub host_struct {
    my %args = @_;

    my $action = $args{action} // 'resolve-mx-address';
    my $type = $args{type} //
        ($action =~ /^resolve-(\w+)-address$/ ? $1 : 'a');

    if ($action =~ /^resolve/) {
        return [412, "For action=resolve-$1-address, type must be $1"]
            if $action =~ /^resolve-(\w+)-address$/ && $type ne $1;

        my ($out, $err);
        system(
            {capture_stdout => \$out, capture_stderr => \$err},
            "host", "-t", $type, $args{name},
            (defined $args{server} ? ($args{server}) : ()),
        );
        log_warn "host: $err" if $err;

        my @res;
        if ($type eq 'a') {
            push @res, $1 while $out =~ / has address (.+)$/gm;
        } elsif ($type eq 'ns') {
            push @res, $1 while $out =~ / name server (.+)\.$/gm;
        } elsif ($type eq 'mx') {
            push @res, $1 while $out =~ / is handled by \d+ (.+)\.$/gm;
        } else {
            return [412, "Don't know yet how to parse type=$type"];
        }

        if ($action =~ /-address$/) {
            my @a;
            for my $n (@res) {
                system(
                    {capture_stdout => \$out, capture_stderr => \$err},
                    "host", "-t", "a", $n,
                );
                log_warn "host: $err" if $err;
                push @a, $1 while $out =~ / has address (.+)$/gm;
            }
            @res = @a;
        }

        return [200, "OK", [sort {$a cmp $b} (uniqstr @res)]];
    } else {
        return [400, "Unknown action '$action'"];
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See the included script L<host-struct>.


=head1 ENVIRONMENT


=head1 SEE ALSO

L<Net::DNS>
