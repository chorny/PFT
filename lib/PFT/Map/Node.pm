package PFT::Map::Node v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map::Node - Node of a PFT site map

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Carp;

sub new {
    my($cls, $from, $kind, $seqnr) = @_;

    my($hdr, $page);
    if ($from->isa('PFT::Header')) {
        $hdr = $from;
    } else {
        confess 'Allowed only PFT::Header or PFT::Content::Page'
            unless $from->isa('PFT::Content::Page');
        ($page, $hdr) = ($from, $from->header);
    }

    bless {
        id => do {
            if ($kind eq 'b' || $kind eq 'm') {
                $kind .= '.' . $hdr->date->repr('.')
            }
            $kind =~ /^m/ ? $kind : $kind . '.' . $hdr->slug
        },
        seqnr => $seqnr,
        hdr => $hdr,
        page => $page,
    }, $cls;
}

=head2 Properties

=over 1

=item header

Header associated with this node.

This property is guarranteed to be defined, even if the node does not
correspond to an existing page.

=cut

sub header { shift->{hdr} }

=item page

The page associated with this node. This property could return undefined
for the nodes which do not correspond to any content. In this case we talk
about I<virtual pages>, in that the node should be represented anyway in a
compiled PFT site.

=cut

sub page { shift->{page} }
sub date { shift->{hdr}->date }
sub next { shift->{next} }
sub seqnr { shift->{seqnr} }
sub id { shift->{id} }

use WeakRef;

sub prev {
    my $self = shift;
    return $self->{prev} unless @_;

    my $p = shift;
    weaken($self->{prev} = $p);
    weaken($p->{next} = $self);
}

sub month {
    my $self = shift;
    unless (@_) {
        exists $self->{month} ? $self->{month} : undef;
    } else {
        confess 'Must be dated and date-complete'
            unless eval{ $self->{hdr}->date->complete };

        my $m = shift;
        weaken($self->{month} = $m);

        push @{$m->{days}}, $self;
        weaken($m->{days}[-1]);
    }
}

sub add_tag {
    my $self = shift;

    my $t = shift;
    push @{$self->{tags}}, $t;
    weaken($self->{tags}[-1]);

    push @{$t->{tagged}}, $self;
    weaken($t->{tagged}[-1]);
}

sub _list {
    my($self, $name) = @_;
    exists $self->{$name}
        ? wantarray ? @{$self->{$name}} : $self->{$name}
        : wantarray ? () : undef
}

sub tags { shift->_list('tags') }
sub tagged { shift->_list('tagged') }
sub days { shift->_list('days') }

=back

=cut

use overload
    '<=>' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{seqnr} <=> $oth->{seqnr};
        $swap ? -$out : $out;
    },
    '""' => sub {
        'PFT::Map::Node[id='.shift->{id}.']'
    },
;

1;
