use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Search::FreeText',
    'VERSION_FROM'	=> 'FreeText.pm', # finds $VERSION
    'PREREQ_PM'		=> {'DB_File' => 1.73,
			    'Lingua::Stem' => 0.50
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FreeText.pm', # retrieve abstract from module
       AUTHOR     => 'Stuart Watt <S.N.K.Watt@rgu.ac.uk>',
       BINARY_LOCATION => 'Search-FreeText-0.05.tar.gz') : ()),
);

sub MY::libscan {
    package MY;
    my ($self, $filename) = @_;
    if ($filename !~ /~$/) {
	return $self->SUPER::libscan($filename);
    } else {
	return "";
    };
};
