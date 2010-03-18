package AXL::Client::Simple::Phone;
use Moose;

use AXL::Client::Simple::LineResultSet;
#use AXL::Client::Simple::Profile;
use Carp;

has client => (
    is => 'ro',
    isa => 'AXL::Client::Simple',
    required => 1,
    weak_ref => 1,
);

has stash => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has currentProfileName => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    lazy_build => 1,
);

sub _build_currentProfileName { return (shift)->stash->{currentProfileName} }

has loginUserId => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    lazy_build => 1,
);

sub _build_loginUserId { return (shift)->stash->{loginUserId} }

sub has_active_em {
    my $self = shift;
    return ($self->has_currentProfileName && $self->has_loginUserId);
}

has currentProfile => (
    is => 'ro',
    isa => 'AXL::Client::Simple::Profile',
    lazy_build => 1,
);

sub _build_currentProfile {
    my $self = shift;
    return $self if not $self->has_active_em;

    my $profile = $self->client->getDeviceProfile(
        profileName => $self->currentProfileName);

    if (exists $profile->{'Fault'}) {
        my $f = $profile->{'Fault'}->{'faultstring'};
        croak "Fault status returned from server in _build_currentProfile: $f\n";
    }

    return AXL::Client::Simple::Profile->new({
        client => $self->client,
        stash  => $profile->{'parameters'}->{'return'}->{'profile'},
    });
}

has lines => (
    is => 'ro',
    isa => 'AXL::Client::Simple::LineResultSet',
    lazy_build => 1,
);

sub _build_lines {
    my $self = shift;

    my @lines = map { { stash => $_ } }
                map { $_->{'parameters'}->{'return'}->{'directoryNumber'} }
                map { $self->client->getLine(uuid => $_) }
                map { $_->{'dirn'}->{'uuid'} }
                    @{ $self->stash->{'lines'}->{'line'} || [] };

    return AXL::Client::Simple::LineResultSet->new({items => \@lines});
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

EWS::Client::Contacts - Contact Entries from Microsoft Exchange Server

=head1 VERSION

This document refers to version 0.01 of EWS::Client::Contacts

=head1 SYNOPSIS

First set up your Exchange Web Services client as per L<EWS::Client>:

 use EWS::Client;
 
 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then retrieve the contact entries:

 my $entries = $ews->contacts->retrieve;
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->DisplayName, "\n";
 }

=head1 DESCRIPTION

This module allows you to retrieve the set of contact entries for a user
on a Microsoft Exchange server. At present only read operations are supported.
The results are available in an iterator and convenience methods exist to
access the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Client::Contacts->new( \%arguments )

You would not normally call this constructor. Use the L<EWS::Client>
constructor instead.

Instantiates a new contacts reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<client> => C<EWS::Client> object (required)

An instance of C<EWS::Client> which has been configured with your server
location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=back

=head2 QUERY AND RESULT SET

=head2 $contacts->retrieve( \%arguments )

Query the Exchange server and retrieve contact entries. Pass the following
arguments in a hash ref:

=over 4

=item C<email> => String (optional)

By default the C<retrieve()> method will return contacts for the account under
which you authenticated to the Exchange server (that is, the credentials
passed to the L<EWS::Client> constructor).

Passing the primary SMTP address of another account will retrieve the contacts
for that Exchange user instead, assuming you have rights to see their
contacts. If you do not have rights, an error will be thrown.

If you pass one of the account's secondary SMTP addresses this module
I<should> be able to divine the primary SMTP address required.

=back

The returned object contains the collection of contact entries and is of type
C<EWS::Contacts::ResultSet>. It's an iterator, so you can walk through the
list of entries (see the synposis, above). For example:

 my $entries = $contacts->retrieve({email => 'nobody@example.com'});

=head2 $entries->next

Provides the next item in the collection of contact entries, or C<undef> if
there are no more items to return. Usually used in a loop along with
C<has_next> like so:

 while ($entries->has_next) {
     print $entries->next->DisplayName, "\n";
 }

=head2 $entries->peek

Returns the next item without moving the state of the iterator forward. It
returns C<undef> if it is at the end of the collection and there are no more
items to return.

=head2 $entries->has_next

Returns a true value if there is another entry in the collection after the
current item, otherwise returns a false value.

=head2 $entries->reset

Resets the iterator's cursor, so you can walk through the entries again from
the start.

=head2 $entries->count

Returns the number of entries returned by the C<retrieve> server query.

=head2 $entries->items

Returns an array ref containing all the entries returned by the C<retrieve>
server query. They are each objects of type C<EWS::Contacts::Item>.

=head2 ITEM PROPERTIES

=head2 $item->DisplayName

The field you should use to describe this entry, being probably the person or
business's name.

=head2 $item->PhoneNumbers

This property comprises all the phone numbers associated with the contact.

An Exchange contact has a number of fields for storing numbers of different
types, such as Mobile Phone, Business Line, and so on. Each of these may in
turn store a free text field so people often put multiple numbers in,
separated by a delimiter.

In this property you'll find a hash ref of all this data, with keys being the
number types (Mobile Phone, etc), and values being array refs of numbers. The
module splits up number lists but preserves their order. For example:

 my $numbers = $entry->PhoneNumbers;
 
 foreach my $type (keys %{ $numbers }) {
 
     foreach my $extn (@{ $numbers->{$type} }) {
 
         print "$type : $extn \n";
     }
 }
 
 # might print something like:
 
 Oliver Gorwits : 73244
 John Smith : 88888

In the future this format may change, or may migrate into an object based
storage.

=head1 TODO

There should be more properties imported than just the DisplayName and
PhoneNumbers.

PhoneNumbers will maybe migrate into some kind of object based storage.

=head1 SEE ALSO

=over 4

=item * L<http://msdn.microsoft.com/en-us/library/aa580675.aspx>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) University of Oxford 2010.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
