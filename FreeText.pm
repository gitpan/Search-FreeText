package Search::FreeText;

use strict;
use warnings;

use Search::FreeText::LexicalAnalysis;

our $VERSION;

$VERSION = "0.05";

=head1 NAME

Search::FreeText - Free text indexing module for medium-to-large text corpuses

=head1 SYNOPSIS

 my $test = new Search::FreeText(-db => ['DB_File', "stories.db"]);

 $text->open_index();
 $text->clear_index();
 $text->index_document(1, "Hello world");
 $text->index_document(2, "World in motion");
 $text->index_document(3, "Cruel crazy beautiful world");
 $text->index_document(4, "Hey crazy");
 $text->close_index();

 $text->open_index();
 foreach ($text->search("Crazy", 10)) {
     print "$_->[0], $_->[1]\n";
 };
 $text->close_index();

=head1 DESCRIPTION

This module provides free text searching in a relatively open manner.
It allows a persistent inverted file index to be constructed and
managed (within limits), and then to be searched fairly efficiently.
The module depends on a DBM module of some kind to manage the 
inverted file (DB_File is usually the best choice, as it is quite
fast, quite scaleable, and accepts the long values that are needed
for performance. 

The free text searching algorithm used is the BM25 weighting scheme
described in Robertson, S. E., Walker, S., Beaulieu, M. M., 
Gatford, M., and Payne, A. (1995). Okapi at TREC-4, in NIST
Special Publication 500-236, the Fourth Text Retrieval Conference
(TREC-4), pages 73-96. 

Much of the module depends on an open lexical analysis system, which
is implemented by Search::FreeText::LexicalAnalysis. This is where
all the word splitting and stemming is handled (Lingua::Stem is
used for the stemming). 

Using the module is quite simple: you can open an index and close it,
and while it is open you add documents as strings, each with a key of your
own choosing.  You can search the corpus using a string, and you get
back a list of matches, each an array of your own document key and a 
relevance measure.  So, for example, the keys might be database table
keys, URLs, file names, anything like that will do. This makes 
Search::FreeText a very useful package to implement fairly efficient and
high quality search systems. 

=head1 METHODS

=over 4

=item new Search::FreeText(arguments...);

Makes a new free text searching object.  The following initialization
parameters are supported:

=over 4

=item -db

Parameters to be passed to the tie function to connect to the 
database module.  The first parameter is assumed to be a Perl module,
and will be required. 

=item -filters

A list of filters, which is passed to
Search::FreeText::LexicalAnalysis. If none is provided here, the default
is used, which is, in order:
Search::FreeText::LexicalAnalysis::Heuristics,
Search::FreeText::LexicalAnalysis::Tokenize,
Search::FreeText::LexicalAnalysis::Stop, and
Search::FreeText::LexicalAnalysis::Stem.

=item -stoplist

This is optional, but if provided, is a big string containing the stop
list.  The Search::FreeText::LexicalAnalysis::Stop module looks here for 
a stop list, and if one is provided, it uses it rather than defaulting
to its own. 

=item -values

Sets the BM25 parameters.  The value should be hash reference containing
the key values for B, K1, and K3 in the BM25 matching measure.  The default
values for these parameters are 0.75, 1.2, and 7 respectively. 

=back

=cut

sub new {
    my ($class, @args) = @_;
    $class = ref($class) || $class;
    my $self = { @args };

    unless (exists($self->{LexicalAnalyser})) {
	my $filters = delete($self->{-filters});
	my @filters = ($filters) ? @$filters : ();
	my $lexical = new Search::FreeText::LexicalAnalysis
	    (-search => $self,
	     ($filters ? (-filters => $filters) : ()));
	$self->{LexicalAnalyser} = $lexical;
    };

    $self = bless $self, $class;
    return $self;
};

=item $self->open_index();

This method is called to open the index database file. Underneath, this calls
the tie function, with the parameters passed using the -args keyword when the
object was initialized. 

=cut

sub open_index {
    my ($self) = @_;
    my @tieargs = @{$self->{-db}};
    my $classname = shift @tieargs;

    my $file = $classname;
    $file =~ s|::|/|g;
    $file .= ".pm";
    
    require($file) or die "$!";
    my %db;

    my $result = tie %db, $classname, @tieargs;
    die "Error opening " . join(", ", @tieargs) . ": $!" unless ($result);
    $self->{_Database} = \%db;
};

=item $self->close_index();

This method is called to close the index database file.  

=cut

sub close_index {
    my ($self) = @_;
    delete($self->{_Database});
};

=item $self->clear_index();

This method can be used to clear the index database file, which should be
open at the time. 

=cut

sub clear_index {
    my ($self) = @_;
    %{$self->{_Database}} = ();
};

=item $self->index_document(documentkey, string);

This is the method which adds a new document to the index. Your chosen
document key can be passed as the first parameter: this value will be 
passed back to you when a search matches this document, but it can be
more or less any string you like. The string is passed to the lexical
analyser before the document is added to the free text index. 

=cut

sub index_document {
    my ($self, $key, $document) = @_;
    my $result = $self->{LexicalAnalyser}->process($document);
    my $docsize = @$result;
    my $docid = $self->get_new_document_id($key, $docsize);
    $self->add_document($docid, $key, $docsize, $result);
    $document = join(", ", @$result);
};

=item $self->add_document(documentid, documentkey, documentsize, word);

The internal method which adds a new document to the inverted file 
database.  You shouldn't need to worry about this, as it will be called
automatically by index_document. 

=cut

sub add_document {
    my ($self, $docid, $key, $docsize, $words) = @_;
    my $database = $self->{_Database};
    my %count = ();
    foreach (@$words) {
	$count{$_}++;
    };
    my @terms = keys %count;
    foreach my $term (@terms) {
	my $value = $database->{$term};
	my ($keys, $data) = split(":", $value || "");
	my $thiswordcount = $count{$term};
	my ($wordcount) = split(",", $data || "");
	$wordcount |= 0;
	$wordcount += $thiswordcount;
	my $next = ($thiswordcount > 1) ? "$docid=$thiswordcount" : $docid;
	$keys = ($keys) ? ("$keys;$next") : $next;
	$database->{$term} = "$keys:$wordcount";
    };
    $database->{" $docid"} = 
	join(";", map { my $count = $count{$_};
			s/([;=\\])/\\$1/go;
			($count > 1) ? ("$_=$count{$_}") : ($_); } @terms) .
			    ":$docsize,$key";
};

=item $self->get_new_document_id(documentkey, documentsize);

An internal method which generates and allocates a new document id for
the given document key, and updates the database to include it.  This
method is called automatically when a document is being indexed. 

=cut

sub get_new_document_id {
    my ($self, $key, $docsize) = @_;
    my $database = $self->{_Database};
    my $id = $database->{"\t$key"};
    die "Document already indexed" if ($id);
    my $global = $self->{_Database}->{" "};
    my ($documentcount, $totalterms, $freedoc) = split(",", $global || "");
    $totalterms |= 0;
    $totalterms += $docsize;
    $freedoc |= "";
    if (! $freedoc) {
	$documentcount++;
	$database->{"\t$key"} = $documentcount;
	$self->{_Database}->{" "} = "$documentcount,$totalterms,$freedoc";
	return $documentcount;
    } else {
	# We have a chain of deallocated documents that we can use.  Pop
	# the top document id from the list and reuse that one! 
	my $next = $database->{" $freedoc"};
	die "Internal consistency error" unless ($next);
	$self->{_Database}->{" "} = "$documentcount,$totalterms,$next";
	$database->{"\t$key"} = $freedoc;
	return $freedoc;
    };
};

=item $self->search_with_callback(words, subroutine);

This is the core of the searching system. words can either be a string or
an array of words - if a string the lexical analyser is used to turn it
into an array of words.  This is then used to search the index, and for
each match, the subroutine is called with the Search::FreeText instance as the
first parameter (in case it's a method), and the document key, relevance
measure, database handle, and internal document id.  The last two parameters
are not to be mucked about with!

=cut

sub search_with_callback {
    my ($self, $words, $sub) = @_;
    if (! ref($words)) {
	$words = $self->{LexicalAnalyser}->process($words);
    } elsif (ref($words) ne 'ARRAY') {
	die "Invalid search string: $words";
    };

    my $database = $self->{_Database};
    my %count = ();
    foreach (@$words) {
	$count{$_}++;
    };
    # First of all, how many documents are we dealing with?
    # And secondly, stored in the same place, how many terms are there in total?

    my $global = $self->{_Database}->{" "};

    die "Empty index" unless ($global);

    my ($documentcount, $totalterms, $freedoc) = split(",", $global || "");
    my $meandocsize = $totalterms / $documentcount;

    my $values = $self->{-values} || {};

    my $B = $values->{B} || 0.75;
    my $K1 = $values->{K1} || 1.2;
    my $K3 = $values->{K3} || 7;
    die "Assertion failed: invalid K1" unless ($K1 >= 0);
    die "Assertion failed: invalid K3" unless ($K3 >= 0);
    die "Assertion failed: invalid B" unless ((0 <= $B) and ($B <= 1));
    
    my $K1plus1 = $K1 + 1;
    my $K3plus1 = $K3 + 1;
    my $Bfrom1 = 1 - $B;
  
  
    # Now we come to the main scoring part of the system.  Quite a bit of this
    # involves parsing some of the stuff that comes in from the database.  This
    # would have to happen anyway, but we have to do it here to be boring. 

    my %result = ();
    my %length_cache = ();
    my $termcount = 0;

    # This could be handled more efficiently using PDL, but it does
    # really need the code to be restructured a bit, and that will take
    # a little time. 

    foreach my $term (keys %count) {
	$termcount++;
	my $value = $database->{$term};
	next unless $value;
	my ($keys, $data) = split(":", $value);
	my ($termcount) = split(",", $data);
	my @docs = split(";", $keys);
	
	my $idf = log($documentcount / (scalar(@docs)));
	my $qtf = ($count{$term} * $K3plus1) / ($count{$term} + $K3);
	foreach my $assoc (@docs) {
	    my ($docid, $count) = ($assoc =~ /^(\d+)(?:=(\d+))?$/);
	    $count |= 1;
	    
	    my $documentlength = $length_cache{$docid};
	    unless ($documentlength) {
		my $document = $database->{" $docid"};
		
		# Assumed that the document length is the first field after 
		# all the terms in the document record. 

		($documentlength) = ($document =~ /:(\d+),/);
		die "Couldn't find document length" unless ($documentlength);
		$length_cache{$docid} = $documentlength;
	    };
	    
	    my $length_weight = $Bfrom1 + ($B * $documentlength / $meandocsize);
	    my $tf = ($count * $K1plus1) / ($count + ($K1 * $length_weight));
	    $result{$docid} = 0 unless (exists($result{$docid}));
	    $result{$docid} += ($tf * $idf * $qtf);
	};
    };

    foreach (keys %result) {
	$result{$_} = $result{$_} / $termcount;
    };

    my @matches = sort { $result{$b} <=> $result{$a} } keys %result;
    foreach (@matches) {
	my $docrecord = $database->{" $_"};

	# Really inefficient due to backtracking!!
	my $last = rindex($docrecord, ",");
	my $key = ($last == -1) ? $docrecord : substr($docrecord, 1 + $last);
	my $result = &$sub($self, $key, $result{$_}, $database, $_);
	last unless ($result);
    };
};

=item $self->search(string, limit);

Searches the free text index, returning up to limit matches.  Each match 
is returned as an array of two elements: first is the document key, and 
second is a relevance measure.  The matches will be sorted when they are
returned.  

Internally, the search method calls the search_with_callback method, but
for most purposes, this is an easier way to get the matches that you need. 
However, under a few circumstances, search_with_callback may be needed to
process the matches.  For example, if the search needed to be filtered in
some way, you could do this by overriding search_with_callback. 

=cut

sub search {
  my ($self, $string, $limit) = @_;
  my $count = 0;
  my @results = ();
  $self->search_with_callback($string,
			      sub { my ($self, $key, $value, $database, $id) = @_;
				    push @results, [$key, $value];
				    return ((! $limit) or ($count++ <= $limit));
				} );
  return @results;
};

1;

=back

=head1 CHANGES

=over 4

=item 0.05

Improved documentation to an almost acceptable standard, included
tests, and quite a few other cleanups to make this the first
essentially usable distribution. 

=item 0.04 

Major performance problem in search_with_callback.  99% of the CPU
time had nothing to do with searching, due to stupidly large amounts
of backtracking in a pattern match, where we just wanted the end part
of a string.  Used rindex instead to achieve the same effect with
huge performance improvement. 

=item 0.03

Alpha-test distribution.

=item 0.02

Fixed the module distribution to contain the proper version of Search.pm,
not the version that was autogenerated by h2xs and which trampled the
original. 

=item 0.01

Beginning of the Search::FreeText class.  

=back

=head1 AUTHORS

Stuart Watt <S.N.K.Watt@rgu.ac.uk>.

Copyright (c) 2003. The Robert Gordon University. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 0.05 - 18th March 2003

=cut
