# @(#) Multipart.pm - <DESCRIPTION>
#
# Author:
#      Dave Roberts
#      Orien Vandenbergh
#
# Synopsis:
#      Multipart.pm
#
# Version
#      $Source: D:/src/perl/Net/SMTP/RCS/Multipart.pm $
#      $Revision: 1.5.1 $
#      $State: Exp $
#
# Description:
#      <FULL DESCRIPTION>
#
#******************************************************************************
package Net::SMTP::Multipart;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use MIME::Base64;
use Net::SMTP;

@ISA = qw(Net::SMTP);

our($b);

our $VERSION = sprintf("%s", q$Revision: 1.5.1 $ =~ /([\d.]+)/);


sub new {
    my $c          = shift;         # What class are we constructing?
    my $classname  = ref($c) || $c;
    my $self       = $classname->SUPER::new(@_);
    $self->_init(@_) if defined ($self);
    return $self;                   # And give it back
}

sub _init {
    my $self = shift;
    # Create arbitrary boundary text
    my ($i,$n,@chrs);
    $b = "";
    foreach $n (48..57,65..90,97..122) { $chrs[$i++] = chr($n);}
    foreach $n (0..20) {$b .= $chrs[rand($i)];}
}

sub Header {
    my $self = shift;
    my %arg  = @_;
  	carp 'Net::SMTP::Multipart:Header: must be called with a To value' unless $arg{To};
  	carp 'Net::SMTP::Multipart:Header: must be called with a Subj value' unless $arg{Subj};
  	carp 'Net::SMTP::Multipart:Header: must be called with a From value' unless $arg{From};

    my (@to, $toString, $ccString);

    if (ref($arg{To}) eq 'ARRAY') {
        push @to, @{$arg{To}};
        $toString = join ", ", @to;
    } else {
        push @to, $arg{To};
        $toString = $arg{To};
    }

    if (ref($arg{Cc}) eq 'ARRAY') {
        if (@{$arg{Cc}}) {
            push @to, @{$arg{Cc}};
            $ccString = join ", ", @{$arg{Cc}}; 
        }
    } else {
       if ($arg{Cc}) {
           push @to, $arg{Cc};
           $ccString = $arg{Cc};
       }
    }
    
    if (ref($arg{Bcc}) eq 'ARRAY') {
        if (@{$arg{Bcc}}) {
            push @to, @{$arg{Bcc}};
            # No string for Bcc, because it's hidden
        }
    } else {
        if ($arg{Bcc}) {
            push @to, $arg{Bcc};
        }
    }
    
  	$self->mail($arg{From});    # Sender Mail Address
    $self->to(@to);             # Recipient Mail Addresses
    $self->data();
    $self->datasend("To: $toString\n");
    $self->datasend("Cc: $ccString\n") if ($ccString);
    $self->datasend("Subject: $arg{Subj}\n");
    $self->datasend("MIME-Version: 1.0\n");
    $self->datasend(sprintf "Content-Type: multipart/mixed; BOUNDARY=\"%s\"\n",$b);
}

sub Text {
    my $self = shift;
    $self->datasend(sprintf"\n--%s\n",$b);
    $self->datasend("Content-Type: text/plain\n\n");
    foreach my $text (@_) {
      $self->datasend($text);
    }
    $self->datasend("\n\n");
}

sub FileAttach {
    my $self = shift;
    foreach my $file (@_) {
      my $displayname;
      if (ref($file) eq 'ARRAY') {
          $displayname = $file->[0];
          $file = $file->[1];
      } else {
          $displayname = $file;
      }
	  unless (-f $file) {
        carp 'Net::SMTP::Multipart:FileAttach: unable to find file $file';
        next;
      }
      my($bytesread,$buffer,$data,$total);
      open(FH,"$file") || carp "Net::SMTP::Multipart:FileAttach: failed to open $file\n";
      binmode(FH);
      while ( ($bytesread=sysread(FH,$buffer, 1024))==1024 ){
        $total += $bytesread;
        # 500K Limit on Upload Images to prevent buffer overflow
        #if (($total/1024) > 500){
        #  printf "TooBig %s\n",$total/1024;
        #  $toobig = 1;
        #  last;
        #}
        $data .= $buffer;
      }
      if ($bytesread) {
        $data .= $buffer;
        $total += $bytesread ;
      }
      #print "File Size: $total bytes\n";
      close FH;

      if ($data){
        $self->datasend("--$b\n");
        $self->datasend("Content-Type: ; name=\"$displayname\"\n");
        $self->datasend("Content-Transfer-Encoding: base64\n");
        $self->datasend("Content-Disposition: attachment; =filename=\"$displayname\"\n\n");
        $self->datasend(encode_base64($data));
        $self->datasend("--$b\n");
      }
    }
}



sub End {
    my $self = shift;
    $self->datasend(sprintf"\n--%s--\n\n",$b);                 # send boundary end message
    foreach my $epl (@_) {
      $self->datasend("$epl");                               # send epilogue text
    }
    $self->datasend("\n");                                   # send final carriage return
    $self->dataend();                                        # close the message
    return $self->quit();                                    # quit and return the status
}


sub mail {
    my $self = shift;
    $self->SUPER::mail(@_);
}

sub to {
    my $self = shift;
    $self->SUPER::to(@_);
}

sub data {
    my $self = shift;
    $self->SUPER::data(@_);
}

sub datasend {
    my $self = shift;
    #printf "datasend: %s\n",@_;
    $self->SUPER::datasend(@_);
}
sub dataend {
    my $self = shift;
    $self->SUPER::dataend();
}

sub quit {
    my $self = shift;
    $self->SUPER::quit(@_);
}




1;

__END__

=head1 NAME

    Multipart.pm

=head1 SYNOPSIS

  $smtp = Net::SMTP::Multipart->new("mailrelay.someco.com");
  $smtp->Header(To   => "someone\@someco.com",
                Subj => "Multipart Mail Demo",
                From => "me\@someco.com");
  $smtp->Text("This is the first text part of the message");
  $smtp->FileAttach("c:/tmp/myfile.xls");
  $smtp->End();

=head1 DESCRIPTION

This module uses the Net::SMTP and Mime::Base64 modules to compose and send
multipart mail messages.  It uses the Net::SMTP methods, but simplifies formatting
of multipart messages using its internal methods Header, Text, FileAttach and End.

=head1 METHODS

=over 2

=item B<new>

The B<new> method invokes a new instance of the Net::SMTP::Multipart class, using the same
arguments as the parent method.

=item B<Header>

The B<Header> method creates the header of the multipart message.  It should be called with
the following arguments

=over 4 

=item B<To>

an array of mail addresses to which the mail is to be sent

=item B<From>

the mail address from which the mail is sent

=item B<Subj>

the subject title of the mail

=back

Additionally, you can specify the following additional arguments, if desired

=over 4

=item B<Cc>

an array of mail addresses which should receive carbon copies of the mail

=item B<Bcc>

an array of mail addresses which should receive blind carbon copies of the mail

=back

=item B<Text>

This method generates a text part to the message.  The argument provided is treated as text and
populates the text part of the message.

=item B<FileAttach>

This method includes a file (identified in the argument when this is called)
within an encoded part of the message. Alternatively, this function can also be
called with a reference to a two item array with a display filename as it's
first element, and the actual filename as it's second.

=item B<End>

This method generates an epilogue part to the message.  The argument provided is treated as text and
populates the epilogue (which most mail agents do not display).  The mail message is then sent and
the class instance destroyed.

=back

=head1 REQUIRED MODULES

C<Carp>

C<MIME::Base64>

C<Net::SMTP>

C<strict>

C<vars>

=head1 SEE ALSO

=head1 EXAMPLES

  $smtp = Net::SMTP::Multipart->new("mailrelay.someco.com");
  $smtp->Header(To   => "someone\@someco.com",
                Cc   => [ "someoneelse\@example.com", "ceo\@example.com" ],
                Bcc  => "coworker\@someco.com",
                Subj => "Multipart Mail Demo",
                From => "me\@someco.com");
  $smtp->Text("This is the first text part of the message");
  $smtp->FileAttach( [ 'ReadThis.doc', 'c:/tmp/ImportantInternalDocument.doc' ]);
  $smtp->End();

=head1 TO DO

=head1 AUTHOR

Dave Roberts
Orien Vandenbergh

=head1 SUPPORT

You can contact Orien for bug reports and suggestions for improments on
this module at perl@icecode.com.  I'll be happy to help in any way that
I can.  In addition, I'll leave the original author's information here
in case you have more luck contacting him than I did.


You can send bug reports and suggestions for improvements on this module
to me at DaveRoberts@iname.com. However, I can't promise to offer
any other support for this script.  

=head1 COPYRIGHT

This script is Copyright © 2002 Dave Roberts. All rights reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This script is distributed in the
hope that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. The copyright holder of this script can not be held liable
for any general, special, incidental or consequential damages arising
out of the use of the script.

=head1 CHANGE HISTORY

$Log: Multipart.pm $

Revision 1.5.1 2006/01/26 14:34:27  Orien Vandenbergh
Fixed the bugs I mentioned in ticket 7706 at http://rt.cpan.org/Public/Bug/Display.html?id=7706

Revision 1.5  2002/11/11 12:12:18  Dave.Roberts
corrected bug in documentation synopsis - changed
Net::SMTP::MultiPart to Net::SMTP::Multipart

Revision 1.4  2002/04/05 11:36:33  Dave.Roberts
change to version number generation code

Revision 1.3  2002/03/27 09:16:29  Dave.Roberts
initial pod added

Revision 1.2  2002/03/26 12:03:23  Dave.Roberts
added basic pod structure


=cut
