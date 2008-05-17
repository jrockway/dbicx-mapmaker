use strict;
use warnings;
use Test::More tests => 2;
use DBICx::TestDatabase;
use ok 'DBICx::MapMaker';

{ package MySchema;
  use strict;
  use warnings;
  use base 'DBIx::Class::Schema';
  __PACKAGE__->load_classes;
  
  1;

  package MySchema::A;
  use base 'DBIx::Class';
  __PACKAGE__->load_components('Core');
  __PACKAGE__->table('A');
  __PACKAGE__->add_columns(
      id  => { data_type => 'INTEGER' },
      foo => { data_type => 'TEXT' },
  );
  __PACKAGE__->set_primary_key('id');

  package MySchema::B;
  use base 'DBIx::Class';
  __PACKAGE__->load_components('Core');
  __PACKAGE__->table('b');
  __PACKAGE__->add_columns(
      id  => { data_type => 'INTEGER' },
      foo => { data_type => 'TEXT' },
  );
  __PACKAGE__->set_primary_key('id');

  package MySchema::MapAB;
  use DBICx::MapMaker;
  use base 'DBIx::Class';
  
  my $map = DBICx::MapMaker->new(
      left_class  => 'MySchema::A',
      right_class => 'MySchema::B',
  
      left_name   => 'as',
      right_name  => 'bs',
  );
    
  $map->setup_table(__PACKAGE__);
}

$INC{'MySchema.pm'} = 1;

my $db = DBICx::TestDatabase->new('MySchema');
ok $db, 'deployed db ok';
