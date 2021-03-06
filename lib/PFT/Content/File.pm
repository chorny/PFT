package PFT::Content::File v0.5.2;

=encoding utf8

=head1 NAME

PFT::Content::File - On disk content file.

=head1 SYNOPSIS

    use PFT::Content::File;

    my $f1 = PFT::Content::File->new({
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use File::Path qw/make_path/;
use File::Basename qw/basename dirname/;
use File::Spec;

use IO::File;
use Encode::Locale;
use Encode;
use Carp;

use parent 'PFT::Content::Base';

use overload
    '""' => sub {
        my $self = shift;
        my($name, $path) = @{$self}{'name', 'path'};
        ref($self) . "({name => \"$name\", path => \"$path\"})"
    },
;

sub new {
    my $cls = shift;
    my $params = shift;

    exists $params->{path} or confess 'Missing param: path';
    my $path = $params->{path};
    defined $params->{name} or $params->{name} = basename $path;
    my $self = $cls->SUPER::new($params);

    $self->{path} = File::Spec->rel2abs($path);
    $self->{encpath} = encode(locale_fs => $path);
    $self
}

=head1 DESCRIPTION

This class describes a content file on disk.

=head2 Properties

Besides the properties following in this section, more are inherited from
C<PFT::Content::Base>.

=over

=item path

Absolute path of the file on the filesystem.

=cut 

sub path { shift->{path} }

=item encpath

Absolute path, encoded with locale

=cut

sub encpath { shift->{encpath} }

=item filename

Base name of the file

=cut

sub filename { basename shift->{path} }

=item mtime

Last modification time according to the filesystem.

=cut

sub mtime {
    (stat shift->{encpath})[9];
}

=item open

Open a file descriptor for the file:

    $f->open        # Read file descriptor
    $f->open($mode) # Open with r|w|a mode

This method does automatic error checking (confessing on error).

=cut

sub open {
    my($self, $mode) = @_;

    # Regular behavior
    my $encpath = $self->{encpath};
    make_path dirname $encpath if $mode =~ /w|a/;
    IO::File->new($encpath, $mode)
        or confess 'Cannot open "', $self->path, "\": $!"
}

=item touch

Change modification time on the filesytem to current timestamp.

=cut

sub touch {
    shift->open('a')
}

=item exists

Verify if the file exists

=cut

sub exists { -e shift->encpath }

=item empty

Check if the file is empty

=cut

sub empty { -z shift->encpath }

=item unlink

=cut

sub unlink {
    my $self = shift;
    unlink $self->encpath
        or confess 'Cannot unlink "' . $self->path . "\": $!"
}

=item rename_as

Move the file in the filesystem, update internal data.

=cut

# TODO use the path property as setter instead?
sub rename_as {
    my($self, $new_path) = @_;
    my $enc_new_path = encode(locale_fs => $new_path);

    make_path dirname $enc_new_path;
    rename $self->{encpath}, $enc_new_path
        or confess "Cannot rename '$self->{path}' → '$new_path': $!";

    $self->tree->was_renamed($self->{path}, $new_path);
    $self->{path} = $new_path;
    $self->{encpath} = $enc_new_path;
}

=back

=cut

1;
