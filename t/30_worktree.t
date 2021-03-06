use strict;
use warnings;
use Test::More;
use Git::Class::Worktree;
use Path::Tiny qw/path cwd tempdir/;
use Path::Class;

my $cwd; BEGIN { $cwd = cwd; }
my $dir = tempdir(CLEANUP => 1);

local $ENV{GIT_CLASS_TRACE} = 1;

my $tree;

subtest 'chdir' => sub {
  is $cwd => cwd(), 'we are in the current directory';
  $tree = Git::Class::Worktree->new( path => $dir->absolute );

  ok cwd() ne $cwd, 'current directory has changed properly';

  ok cwd() eq path($tree->_path), 'current directory is stored properly';

  ok $cwd eq path($tree->_cwd), 'previous current directory is stored';
};

subtest 'init' => sub {
  ok cwd() eq $dir, "current directory is correct";

  my $got = $tree->init;

  ok $got, "initialized local repository";
  ok !$tree->_error, 'and no error';

  ok $dir->child('.git')->is_dir, '.git exists';
};

subtest 'config' => sub {
  unless ($dir->child('.git')->is_dir) {
    note 'not in a local repository';
    return;
  }

  my $got = $tree->config('user.email' => 'test@localhost');

  ok !$tree->_error, 'set local user.email without errors';

  $got = $tree->config('user.name' => 'foo bar');

  ok !$tree->_error, 'set local user.name without errors';

  my $config = $dir->path('.git/config')->slurp;
  like $config => qr/email\s*=\s*test\@localhost/, "contains user.email";
  like $config => qr/name\s*=\s*(['"]?)foo bar\1/, "contains user.name";
};

subtest 'add' => sub {
  unless ($dir->child('.git')->is_dir) {
    note 'not in a local repository';
    return;
  }

  my $file = $dir->path('README');
  $file->spew('readme');
  ok $file->is_file, "created README file";

  my $got = $tree->add('README');

  ok !$tree->_error, 'added README to the local repository without errors';
};

subtest 'commit' => sub {
  my $got = $tree->commit({ message => 'committed README', author => 'A U Thor <author@example.com>' });

  ok $got, "committed to the local repository";
  ok !$tree->_error, 'and no error';
};

subtest 'demolish' => sub {
  ok $cwd ne cwd(), 'current directory is not the same as the stored directory';

  undef $tree; # to demolish

  ok $cwd eq cwd(), 'restored previous current directory after demolishing';
};

subtest 'clone' => sub {
  chdir '/tmp';

  use Git::Class::Cmd;
  my $git = Git::Class::Cmd->new;
  my $worktree = $git->clone('git://github.com/libgit2/TestGitRepository.git');

  my @changes;
  eval {
    @changes = file( '/tmp/TestGitRepository', 'master.txt' )->slurp( chomp => 1 );
  };

  ok scalar @changes;
};


done_testing;

END {
  chdir $cwd if $cwd ne cwd;
  $dir->remove_tree({safe => 0}) if $dir;
}
