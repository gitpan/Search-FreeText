package Search::FreeText::LexicalAnalysis::Tokenize;

# Author: Stuart Watt
# Copyright (c) The Robert Gordon University

use strict;
use warnings;

=head1 NAME

Search::FreeText::LexicalAnalysis::Tokenize - lexicon tokenizer

=head1 DESCRIPTION

A pseudo-filter which should always be called as the first element in the
lexical processing system.  As usual, it can also be overridden.  Called
with an array containing an entire string, it returns a new array containing
a list of words.  

=head1 SYNOPSIS

 my $stemmer = new Search::FreeText::LexicalAnalysis::Tokenize ();
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
does very little, although it could compile and cache stuff if it 
seemed appropriate.  

=cut

sub initialize {
  my ($self) = @_;
};

=item $self->process($oldwords);

Called to process a reference to an array containing strings (well, 
one string) which can then be tokenized for further lexical processing.

=cut

sub process {
  my ($self, $oldwords) = @_;
  my $string = join("\n", @$oldwords);
  my @words = ($string =~ /\w+/g);
  return \@words;
};

1;

__END__

=back

=head1 AUTHOR

Stuart Watt <S.N.K.Watt@rgu.ac.uk>

Copyright (c) 2003 The Robert Gordon University.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
