package Git::Class::Role::Diff;

use Moo::Role; with 'Git::Class::Role::Execute';
use Git::Raw;

sub diff {
  my $self = shift;

  my $path = Path::Tiny->cwd->absolute;
  my $repo = Git::Raw::Repository->open( $path );

  my $status = $repo->status({});

  my @modified_files =
    grep { 'worktree_modified' ~~ $status->{$_}->{flags} }
    keys %$status;

  my $index = $repo->index;
  my $tree  = $repo->head->target->tree;

  # TODO rm from index non modified files

  $index->add($_) for @modified_files;

  my $out;
  my $printer = sub {
    my ($usage, $line) = @_;
    $out .= $line;
  };

  my $diff = $repo->diff({
    'tree'            => $tree,
    'context_lines'   => 3,
    'interhunk_lines' => 0,
  });

  $diff->print("patch", $printer);

  return $out;
}

1;

__END__

=head1 NAME

Git::Class::Role::Diff

=head1 DESCRIPTION

This is a role that does C<git diff ...>. See L<http://www.kernel.org/pub/software/scm/git-core/docs/git-diff.html> for details.

=head1 METHOD

=head2 diff

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
