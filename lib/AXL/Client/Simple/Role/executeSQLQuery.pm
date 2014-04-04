package AXL::Client::Simple::Role::executeSQLQuery;
use Moose::Role;

has executeSQLQuery => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_executeSQLQuery {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'executeSQLQuery',
        transport => $self->transporter->compileClient(
            action => 'CUCM:DB ver=9.1' ),
    );
}

no Moose::Role;
1;

