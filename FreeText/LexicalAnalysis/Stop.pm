package Search::FreeText::LexicalAnalysis::Stop;

# Author: Stuart Watt
# Copyright (c) The Robert Gordon University

use strict;
use warnings;

=head1 NAME

Search::FreeText::LexicalAnalysis::Stop - lexicon interface to a stop list

=head1 DESCRIPTION

A filter which provides stop list filtering.  The stop list is usually
predefined, but additional words can be added, and existing words removed,
by subclassing and overriding the initialize() method.  Note that this
stop list filter is case insensitive.  This is deliberate, but can be
overridden by defining your own subclass if you like.  Quite what a 
case-sensitive stop list might work like I don't really know.  

=head1 SYNOPSIS

 my $stemmer = new Search::FreeText::LexicalAnalysis::Stop ();
 my $words = $lexicaliser->process($oldwords);

=cut

sub new {
    my ($classname, @args) = @_;
    my $class = ref($classname) || $classname;
    my $self = { @args };
    $self = bless $self, $class;
    $self->initialize();
    return $self;
};

=head1 METHODS

=over 4

=item $self->initialize();

Called when the lexicon system is initialised.  This method actually
creates and stores the stop list, and can be overridden if needed.  

=cut

sub initialize {
  my ($self) = @_;
  my $stops = {};
  my $stoplist = $self->get_stop_list();
  foreach my $word (map { (/^\#/) ? () : (split(/\s+/)) } split("\n", $stoplist)) {
    $stops->{lc($word)} = 1;
  };
  $self->{_StopList} = $stops;
};

=item $self->process($oldwords);

Called to process a reference to an array of words, and returns a 
reference to an array of stemmed words for further processing. 

=cut

sub process {
  my ($self, $oldwords) = @_;
  my $stops = $self->{_StopList};
  my @words = grep { ! $stops->{lc($_)} } @$oldwords;
  return \@words;
};

=item $self->get_stop_list()

Called to return a string containing the stop list.  The stop list is
a string containing the stop list words.  It can also include comments
as lines beginning with a '#' character.  You might want to override
this, for example, to pick up the stop list from a file.

The default method will pick up a stop list from the -stoplist
parameter to the main Search::FreeText object, if one has been supplied. 

You can also override this by adding some extra lines and special
words into the stop list, or removing some words, by calling the
default method from within a subclass. 

=cut

sub get_stop_list {
  my ($self) = @_;

  my $search = $self->{-search};
  my $stoplist = $search ? $search->{-stoplist} : "";
  return $stoplist if ($stoplist);

  return <<"END_STOP_LIST";

a about above according across actually adj after afterwards again against all almost
alone along already also although always among amongst an and another any
anyhow anyone anything anywhere are arent around as at
b be became because become becomes becoming been before beforehand begin
beginning behind being below beside besides between beyond billion both but by
c can cant cannot caption co could couldnt
d did didnt do does doesnt dont down during
e each eg eight eighty either else elsewhere end ending enough etc even ever every
everyone everything everywhere except
f few fifty first five for former formerly forty found four from further
g
h had has hasnt have havent he hed hell hes hence her here heres hereafter hereby
herein hereupon hers herself him himself his how however hundred
i id ill im ive ie if in inc indeed instead into is isnt it its itself
j
k know
l last later latter latterly least less let lets like likely ltd
m made make makes many maybe me meantime meanwhile might million miss
more moreover most mostly mr mrs much must my myself
n namely neither never nevertheless next nine ninety no nobody none nonetheless
noone nor not nothing now nowhere
o of off often on once one ones only onto or other others otherwise our ours
ourselves out over overall own
p per perhaps
q
r rather recent recently
s same seem seemed seeming seems seven seventy several she shed shell shes
should shouldnt since six sixty so some somehow someone something sometime
sometimes somewhere still stop such
t taking ten than that thatll thats thatve the their them themselves then thence there
thered therell therere theres thereve thereafter thereby therefore therein thereupon
these they theyd theyll theyre theyve thirty this those though thousand three through
throughout thru thus to together too toward towards trillion twenty two
u under unless unlike unlikely until up upon us used using
v very via
w was wasnt we wed well were weve were werent what whatll whats whatve
whatever when whence whenever where wheres whereafter whereas whereby
wherein whereupon wherever whether which while whither who whod wholl whos
whoever whole whom whomever whose why will with within without wont would
wouldnt
x
y yes yet you youd youll youre youve your yours yourself yourselves
z

END_STOP_LIST
};


1;

=back

=head1 AUTHOR

Stuart Watt <S.N.K.Watt@rgu.ac.uk>

Copyright (c) 2003 The Robert Gordon University.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
