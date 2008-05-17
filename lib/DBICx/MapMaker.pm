package DBICx::MapMaker;
use Moose;
use Moose::Util::TypeConstraints;

# avoid clogging up our methods
my $other = sub { return 'right' if shift eq 'left'; return 'left' };

for my $direction (qw/left right/){
    my $other = $other->($direction);
    my $oname = "${other}_name";

    has "${direction}_class" => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
        coerce   => 1,
    );

    has "${direction}_name" => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has "${direction}_to_map_relation" => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->$oname . '_map';
        }
    );

    has "${other}s_from_${direction}" => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->$oname . 's';
        },
    );

    # TODO support extra columns

    # XXX: hack
    has "suppress_${direction}_m2m" => (
        is      => 'ro',
        isa     => 'Bool',
        default => sub { undef },
    );
}

has tablename => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($l,$r) = ($self->left_name, $self->right_name);
        return "map_${l}_${r}";
    },
);

# load up the classes
sub BUILD {
    my $self = shift;
    for my $class (map { $self->$_ } qw/left_class right_class/){
        Class::MOP::load_class($class);
    }
}

sub setup_table {
    my ($self, $class) = @_;
    $class->load_components(qw/Core/);
    $class->table($self->tablename);

    my ($left_class, $right_class) = ($self->left_class, $self->right_class);
    my ($left_name, $right_name) = ($self->left_name, $self->right_name);

    my $l_info = $left_class->column_info($left_class->primary_columns);
    my $r_info = $right_class->column_info($right_class->primary_columns);

    # NOTE:
    # we never want auto-incrementing
    # in a maping table, so remove it
    # - SL
    delete $_->{is_auto_increment} for ($l_info, $r_info);

    $class->add_columns(
        $left_name  => { %$l_info, is_nullable => 0, },
        $right_name => { %$r_info, is_nullable => 0, },
    );
    $class->set_primary_key($left_name, $right_name);

    # us -> them
    $class->belongs_to( $left_name  => $left_class  );
    $class->belongs_to( $right_name => $right_class );

    # them -> us
    my $lmap = $self->left_to_map_relation;
    my $rmap = $self->right_to_map_relation;
    $left_class->has_many(  $lmap => $class, $left_name  );
    $right_class->has_many( $rmap => $class, $right_name );

    # many2many
    my $rights_from_left = $self->rights_from_left;
    my $lefts_from_right = $self->lefts_from_right;

    $left_class->many_to_many( $rights_from_left  => $lmap => $right_name )
      unless $self->suppress_left_m2m;

    $right_class->many_to_many( $lefts_from_right => $rmap => $left_name  )
      unless $self->suppress_right_m2m;
}

1;

__END__

=head1 NAME

DBICx::MapMaker - automatically create a mapping table

=head1 SYNOPSIS

A common SQL pattern is the "many to many" relationship; where a row
in the "left table" may point to many rows in the "right table", and a
row in the "right table" may point to many rows in the "left table".

This module automatically creates a L<DBIx::Class|DBIx::Class> result
source for that table, and sets up all the necessary relationships.

Here's how to use it.  Imagine you have a table called C<A> and C<B>,
each with a primary key.  To create the mapping table:
