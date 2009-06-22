package TestDB;

use DBI;
use FindBin;
use File::Spec;
use AnyEvent::DBI;

sub _database {
    return File::Spec->catfile(File::Spec->tmpdir, 'hamster.db');
}

sub dbh {
    _create_database();

    my $db = _database();

    return AnyEvent::DBI->new("dbi:SQLite:dbname=$db", "", "");
}

sub dbh_simple {
    _create_database();

    my $db = _database();

    return DBI->connect("dbi:SQLite:dbname=$db", "", "");
}

sub _create_database {
    my $db = _database();

    unless (-f $db) {
        my $dbh = DBI->connect("dbi:SQLite:dbname=$db");

        my $dir = "$FindBin::Bin/../schema/";

        opendir DIR, $dir;

        my @files = grep {m/\.sql$/} readdir DIR;

        closedir DIR;

        foreach my $file (@files) {
            open FILE, "< $dir/$file" or die $!;

            my @content = <FILE>;

            my $drop = shift @content;
            my $create = join('', @content);

            $dbh->do($drop);
            $dbh->do($create);

            close FILE;
        }
    }
}

sub cleanup {
    unlink _database();
}

1;
