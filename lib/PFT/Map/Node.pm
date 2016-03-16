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

    my $node = PFT::Map::Node->($from, $kind, $seqid, $resolver);

=over 1

=item C<$from> can either be a C<PFT::Header> or a C<PFT::Content::Page>;

=item Valid vaulues for C<$kind> match C</^[bmpt]$/>;

=item C<$seqid> is a numeric sequence number.

=head1 DESCRIPTION

=cut

use Carp;
use WeakRef;

use PFT::Text;

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
    $kind =~ /^[bmpt]$/ or confess "Invalid kind $kind. Valid: b|m|p|t";

    bless {
        kind => $kind,
        id => do {
            my $id = $kind;
            $id .= '.' . $hdr->date->repr('.') if $kind =~ '[bm]';
            $kind eq 'm' ? $id : $id . '.' . $hdr->slug
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

sub kind { shift->{kind} }
sub date { shift->{hdr}->date }
sub next { shift->{next} }
sub seqnr { shift->{seqnr} }
sub id { shift->{id} }


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

sub _add {
    my($self, $linked, $ka, $kb) = @_;

    push @{$self->{$ka}}, $linked;
    weaken($self->{$ka}[-1]);

    push @{$linked->{$kb}}, $self;
    weaken($linked->{$kb}[-1]);
}

sub add_tag { shift->_add(shift, 'tags', 'tagged') }

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
