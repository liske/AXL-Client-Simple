package AXL::Client::Simple::DeviceProfile;
use Moose;

use AXL::Client::Simple::LineResultSet;
use Carp;

our $VERSION = '0.01';
$VERSION = eval $VERSION; # numify for warning-free dev releases

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

has lines => (
    is => 'ro',
    isa => 'AXL::Client::Simple::LineResultSet',
    lazy_build => 1,
);

sub _build_lines {
    my $self = shift;

    my @lines = map { { stash => $_ } }
                map { defined $_ ? $_ : () }
                map { $_->{'axlParams'}->{'return'}->{'line'} }
                map { $self->client->getLine->(uuid => $_) }
                map { $_->{'dirn'}->{'uuid'} }
                    @{ $self->stash->{'lines'}->{'line'} || [] };

    return AXL::Client::Simple::LineResultSet->new({items => \@lines});
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

AXL::Client::Simple::DeviceProfile - Properties and Lines on a CUCM Handset

=head1 VERSION

This document refers to version 0.01 of AXL::Client::Simple::DeviceProfile

=head1 SYNOPSIS

First set up your CUCM AXL client as per L<AXL::Client::Simple>:

 use AXL::Client::Simple;
 
 my $cucm = AXL::Client::Simple->new({
     server      => 'call-manager-server.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{AXL_PASS}
 });

Then perform simple queries on the Unified Communications server:

 my $device = $cucm->get_DeviceProfile('SEP001122334455');
 
 my $lines = $device->lines;
 printf "this device has %s lines.\n", $lines->count;
 
 while ($lines->has_next) {
     my $l = $lines->next;
     print $l->alertingName, "\n";
     print $l->extn, "\n";
 }
 
 if ($device->has_active_em) {
     # extension mobility is active, so the lines are different
 
     my $profile = $device->currentProfile;
 
     my $profile_lines = $profile->lines;
     printf "this profile has %s lines.\n", $profile_lines->count;
 
     while ($profile_lines->has_next) {
         my $l = $profile_lines->next;
         print $l->alertingName, "\n";
         print $l->extn, "\n";
     }
 }

=head1 DESCRIPTION

This module allows you to retrieve some properties of a device registered with
a Cisco Unified Communications server, including its line numbers and
extension mobility profile lines.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 AXL::Client::Simple::DeviceProfile->new( \%arguments )

You would not normally call this constructor. Use the L<AXL::Client::Simple>
constructor instead.

=over 4

=item C<< client => >> C<AXL::Client::Simple> object (required)

An instance of C<AXL::Client::Simple> which has been configured with your
server location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=item C<< stash => >> Hash Ref (required)

This hash reference contains the raw data returned from the Unified
Communications server when asked for properties of this device. From this
stash are retrieved data to construct each property as listed below.

=back

=head2 LINES QUERY AND RESULT SET

=head2 $device->lines

Query the Unified Communications server and retrieve DeviceProfile line details for
this device. 

The returned object contains the ordered collection of DeviceProfile lines and is of
type C<AXL::Client::Simple::LineResultSet>. It's an iterator, so you can walk
through the list of lines (see the synposis, above). For example:

 my $lines = $device->lines;

=head2 $lines->next

Provides the next item in the collection of lines, or C<undef> if there are no
more items to return. Usually used in a loop along with C<has_next> like so:

 while ($lines->has_next) {
     print $lines->next->alertingName, "\n";  # the alerting name field from CUCM
     print $lines->next->extn, "\n";          # the DeviceProfile line extension number
 }

=head2 $lines->peek

Returns the next item without moving the state of the iterator forward. It
returns C<undef> if it is at the end of the collection and there are no more
items to return.

=head2 $lines->has_next

Returns a true value if there is another entry in the collection after the
current item, otherwise returns a false value.

=head2 $lines->reset

Resets the iterator's cursor, so you can walk through the entries again from
the start.

=head2 $lines->count

Returns the number of entries returned by the C<lines> server query.

=head2 $lines->items

Returns an array ref containing all the entries returned by the C<lines>
server query. They are each objects of type C<AXL::Client::Simple::Line>.

=head2 DeviceProfile PROPERTIES

=head2 $device->currentProfileName

If the device has Extension Mobility enabled and an extension mobility profile
is active, then its name will be returned by this accessor.

=head2 $device->loginUserId

When Extension Mobility is active, you can find out the username of the logged
in user by querying this property.

=head2 $device->has_active_em

To easily find out whether Extension Mobility is active on a live handset, use
this property which will return a true value if that is the case. Otherwise,
it returns a false value.

=head2 $device->currentProfile

Assuming the device does have Extension Mobility active, then you can grab the
extension mobility profile details from this property. In fact, what is
returned is another instance of C<AXL::Client::Simple::DeviceProfile> (this module)
which in turn allows you to access the profile's line numers via C<lines> as
above.

=head1 SEE ALSO

=over 4

=item * L<http://developer.cisco.com/web/axl>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) University of Oxford 2010.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
