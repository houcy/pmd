#!/usr/bin/perl
$| =1;

use CGI qw(:standard escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use Time::localtime;
use PMD::Project;

$query = new CGI();
print $query->header();

sub nopage() {
 print $query->p("How'd we get here?");
}

sub default() {
 print start_html("Run PMD on your Sourceforge project");
 
 print "<center><a href=\"http://pmd.sourceforge.net/\"><img src=\"http://sourceforge.net/sflogo.php?group_id=56262&type=5\" alt=\"Project Ultra*Log @ DARPA\" border=\"0\" /></a></center>";

 print h3("<center>PMD-WEB</center>");
 print "PMD is a Java source code analysis tool - it checks your code for unused fields, empty try/catch/finally/if/while blocks, unused method parameters, and stuff like that.  There's much more info <a href=\"http://pmd.sf.net/\">here</a>.<p>This table contains the results of running PMD's <a href=\"http://pmd.sourceforge.net/rules/unusedcode.html\">unused code ruleset</a> against a bunch of Sourceforge projects.  The JavaNCSS column contains the lines of code analyzed as reported by the excellent <a href=\"http://www.kclee.com/clemens/java/javancss/\">JavaNCSS</a> utility."; 
 print "<p>Comments?  Questions?  Please post them <a href=\"http://sourceforge.net/forum/forum.php?forum_id=188192\">here</a>.<br>";
 open(FILE,"lastruntime.txt");
 my $lastruntime=<FILE>;
 close(FILE);
 print br();
 print "This report is regenerated 10 minutes past the hour at 0000, 0600, 1200, and 1800 U.S. Pacific Standard Time.<br>The last run finished at ", $lastruntime, ".  Right now it's ", ctime(), ".";
 print "<p><b>1/31/03: The jakarta.apache.org and xml.apache.org projects have been moved <a href=\"http://cvs.apache.org/~tcopeland/pmdweb/\">here</a></b>";
 print br();
 print hr();

 if (param("unixname")) {
  my $project = PMD::Project->new("Sourceforge",param("title"),param("unixname"), param("moduledirectory"), param("srcdir"));
  addProject($project);
  print p(), b("Added "), b($project->getTitle()), b(" to the schedule"), p();
 } 

 print loadProjectList();

 print hr(); 
 print "Want to run PMD on your Java Sourceforge project?  Fill in the blanks and hit go:";
 print start_form();
 print "Project title (i.e., PMD): ", textfield(-name=>'title',-default=>'',-override=>1);
 print br(), "Project's Unix name (i.e., pmd): ", textfield(-name=>'unixname',-default=>'',-override=>1);
 print br(), "Module directory (i.e., pmd-dcpd): ", textfield(-name=>'moduledirectory',-default=>'',-override=>1);
 print br(), "Source directory (including module directory, i.e., pmd-dcpd/src): ", textfield(-name=>'srcdir',-default=>'',-override=>1);
 my $cachebuster=`date`;
 print $query->hidden(-name=>'cachebuster', -value=>${cachebuster});
 print br(), submit(-value=>'Go');
 print end_form();
 
 print hr(); 
}

sub loadProjectList() {
	my @projects = ();
	opendir(DIR, "jobs/") or return "can't open jobs directory!";
	while (defined($file=readdir(DIR))) {
		if ($file =~ /txt/) {
			open(FILE,"jobs/${file}");
 			my $jobdata=<FILE>;
			close(FILE);
			my $project = PMD::Project->new($jobdata);
			push(@projects, $project);
		}
	}

	@newprojects = sort { $a->getPctg() cmp $b->getPctg() } @projects;

	my $result="<table align=center><tr><th>Project</th><th></th><th>Home page</th><th>NCSS</th><th>Problems</th><th>Percentage<br>Unused Code</th><th>Duplicate<br>Code</th></tr>";
	foreach $project (@newprojects) {
		my $jobLink=$project->getTitle();
		if (-e $project->getRptFile()) {
			$jobLink="<a href=\"@{[$project->getRptURL]}\">@{[$project->getTitle()]}</a>";
		}
		$result="${result}<tr><td>${jobLink}</td><td></td><td>@{[$project->getHomePage()]}</td>";
		$result="${result}<td>@{[$project->getNCSS()]}</td>";
		my $pctg = $project->getPctg();
		my $color="red";
		if ($pctg < .2) {
			$color="#00ff00";
		} elsif ($pctg < .8 ) {
			$color="yellow";
		}
		$pctg = sprintf("%0.2f", $pctg);
		if ($project->getNCSS() == "TBD") {
			$pctg = "N/A";
			$color = "white";
		}
		$result="${result}<td align=center>@{[$project->getLines()]}</td><td bgcolor=$color align=center>$pctg</td>";
		my $cpdLink="0";
		if (-e $project->getCPDRptFile() && $project->getCPDLines() > 0) {
			$cpdLink="<a href=\"@{[$project->getCPDRptURL]}\">@{[$project->getCPDLines()]}</a>";
		}
		$result = "${result}<td align=center>$cpdLink</td></tr>";
	}
	$result="${result}</tr></table>";
	return $result;
}

sub addProject() {
	my ($project) = @_;
	#my $cmd = "echo \"@{[$project->getString()]}\" > @{[$project->getJobsFile()]}";
	#my $cmd = "mail tomcopeland@users.sourceforge.net -s \"@{[$project->getString()]}\"";
	#system("${cmd}");
  open(SENDMAIL, "|/usr/lib/sendmail -oi -t -odq") or die "Couldn't send email: $!\n";
  print SENDMAIL <<"EOF";
From: PMD-WEB <tomcopeland\@users.sourceforge.net>
To: Tom Copeland <tomcopeland\@users.sourceforge.net>
Subject: @{[$project->getString()]}

enter it

EOF

  close(SENDMAIL) or warn "Sendmail didn't close nicely";
}

$page=param("state") || "default";

%states = (
 'default'      =>      \&default
);

if ($states{$page}) {
 $states{$page}->();
} else {
 nopage();
}

print $query->end_html();

