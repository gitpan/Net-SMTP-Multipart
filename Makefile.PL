# Net::SMTP::Multipart
#
# Version
#      $Source: D:/src/perl/Net/SMTP/RCS/Makefile.PL $
#      $Revision: 1.3 $
#      $State: Exp $
#
# Start comments/code here - will not be processed into manual pages
#
#    Copyright © Dave Roberts  2000,2001
#
# Revision history:
#      $Log: Makefile.PL $
#      Revision 1.3  2002/04/05 11:38:57  jj768
#      *** empty log message ***
#
#      Revision 1.2  2002/03/27 09:14:48  Dave.Roberts
#      corrected errors (was not creating pod's)
#
#      Revision 1.1  2002/03/26 12:00:56  Dave.Roberts
#      Initial revision
#
#
#
#******************************************************************************

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::SMTP::Multipart',
    'VERSION_FROM'	=> 'Multipart.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      MIME::Base64       => 0,
      Net::SMTP          => 0,
	  Test				 => 0,
  }, # e.g., Module::Name => 1.1
    'dist' => {
      ZIP      => 'wzzip.exe',
      ZIPFLAGS  => "-P",
    },
    HTMLLIBPODS => { 'Multipart.pm'  => 'blib/html/site/lib/Net/SMTP/Multipart.html'},
    MAN3PODS    => { 'Multipart.pm'  => 'blib/man3/Net::SMTP::Multipart.3' },
    PM          => { 'Multipart.pm'  => '$(INST_LIBDIR)/Multipart.pm'}
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: Multipart.pm
\tpod2text Multipart.pm >README
\tpod2html Multipart.pm >Multipart.html
END_OF_POSTAMBLE
}

# Just to make it ignore editor backup files.
sub libscan {
 	$_ = $_[1];
	if ( m/(RCS|CVS|SCCS)/i || m/[~%]$/ || m/\.(orig|rej)$/ ) {
	  print " Ignoring $_\n";
	  return '';
  }
  return $_;
}

