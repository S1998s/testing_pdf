// <cfscript>
  // Ensure TestBox is loaded dynamically
  // testbox = new testbox.system.TestBox(
    // directory = "/specs/",  // Ensure this resolves correctly
    // reporter = "json"
 //  );

  // Run the tests
  // results = testbox.run();

  // Output results
  // writedump(serializeJSON(results));
 // writedump(results);
// </cfscript>
<cfscript>
/*thread {
	try {
		Thread=createObject("java","java.lang.Thread");
		threads=Thread.getAllStackTraces().keySet();
		ignores=[
			"org.apache.tomcat.util.net.NioEndpoint.serverSocketAccept"
			,"java.lang.Thread.getStackTrace(Thread.java:1559)"
			,"org.apache.tomcat.util.net.NioBlockingSelector$BlockPoller.run"
			,"org.apache.tomcat.util.net.NioEndpoint$Poller.run"
			,"org.apache.catalina.startup.Bootstrap.start"
		];
		
		
		while(true) {
			NL="
	";	
			data="";
			// loop threads
			loop collection=threads index="k" item="t" label="outer" {
				
				st=t.getStackTrace();
				state=t.getState().toString();
				str="";
				// loop stacktraces
				loop array=st item="ste" {
					str&=ste;
					str&=NL&"	";
				}

				loop array=ignores item="ignore" {
					if(find(ignore,str))continue "outer";
				}
				if(isEmpty(str)) continue;
				index=find("_testRunner.cfc",str);
				if(index==0) continue;
				if(isEmpty(str) || find("_testRunner.cfc",str)==0) continue;
				data&="#t.name# (#state#)#NL##mid(str,1,index)##NL##NL#";
			}
			dir=getDirectoryFromPath(getCurrentTemplatePath()) ;
			path=dir & "/threads.txt";
			// compare with old one
			if(fileExists(path)) {
				old=fileRead(path);
				old=mid(old,find("<<<<",old)+4);
				if(trim(old)==trim(data)) 	{
					fileWrite(dir & "/threads-#dateTimeFormat(now(),"yyyy-mm-dd-hh-nn-ss")#.txt",">>>>#now()#<<<<#NL##data#");
				}
			}
			if(len(trim(data)))
				fileWrite(path,">>>>#now()#<<<<#NL##data#");
			sleep(3000);
		}
	}
	catch(e) {
		systemOutput("**************",1,1);
		systemOutput(e,1,1);
	}
}*/

request._start = getTickCount();
if (execute) {

request.basedir = basedir;
request.srcall = srcall;
request.testFolder = test;

request.WEBADMINPASSWORD = "webweb";
request.SERVERADMINPASSWORD = "webweb";
server.WEBADMINPASSWORD = request.WEBADMINPASSWORD;
server.SERVERADMINPASSWORD = request.SERVERADMINPASSWORD;

NL = "
";
TAB = "	";
	}
	
	postTestMeM = reportMem( "", _reportMemStat.usage );
	arrayAppend( results, postTestMeM.report, true );
	arrayAppend( results, "Force GC");
	createObject( "java", "java.lang.System" ).gc();
	
	postTestGC = reportMem( "", postTestMeM.usage )
	arrayAppend( results, "");
	arrayAppend( results, postTestGC.report, true );
	
	structClear( CFTHREAD );
	arrayAppend( results, "");
	arrayAppend( results, "Force GC after structClear(cfthread)");
	createObject( "java", "java.lang.System" ).gc();
	arrayAppend( results, "CFTHREADS: #NumberFormat( ThreadData().len() )#");
	if ( !ManagementFactoryError )
		arrayAppend( results, "Active Threads: #NumberFormat( threadCount )#");
	arrayAppend( results, "");
	arrayAppend( results, reportMem( "", postTestGC.usage ).report, true );
	
	arrayAppend( results, "");
	arrayAppend( results, "=============================================================" & NL);
	arrayAppend( results, "-> Bundles/Suites/Specs: #result.getTotalBundles()#/#result.getTotalSuites()#/#result.getTotalSpecs()#");
	arrayAppend( results, "-> Pass:     #result.getTotalPass()#");
	arrayAppend( results, "-> Skipped:  #result.getTotalSkipped()#");
	arrayAppend( results, "-> Failures: #result.getTotalFail()#");
	arrayAppend( results, "-> Errors:   #result.getTotalError()#");
	arrayAppend( results, "-> JUnitReport: #JUnitReportFile#");

	servicesReport = new test._setupTestServices().reportServiceSkipped();
	for ( service in servicesReport ){
		arrayAppend( results, service );
	}
	arrayAppend( results_md, "" );
	loop array=results item="summary"{
		systemOutput( summary, true );
		arrayAppend( results_md, summary );
	}
	arrayAppend( results_md, "" );

	failedServices = new test._setupTestServices().reportServiceFailed();
	if ( len( failedServices ) gt 0 ){
		systemOutput( "", true );
		loop array=failedServices item="failure"{
			systemOutput( failure, true );
			arrayAppend( results_md, failure );
		}
		systemOutput( "", true );
		arrayAppend( results_md, "" );
	}
	
	if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
		github_commit_base_href=  "/" & server.system.environment.GITHUB_REPOSITORY
			& "/blob/" & server.system.environment.GITHUB_SHA & "/";
		github_branch_base_href=  "/" & server.system.environment.GITHUB_REPOSITORY
			& "/blob/" & server.system.environment.GITHUB_REF_NAME & "/";
	}

	if ( !isEmpty( failedTestCases ) ){
		systemOutput( NL );
		for ( el in failedTestCases ){
			arrayAppend( results, el.type & ": " & el.bundle & NL & TAB & el.testCase );
			arrayAppend( results, TAB & el.errMessage );
			arrayAppend( results_md, "#### " & el.type & " " & el.bundle );
			arrayAppend( results_md, "###### " & el.testCase );
			arrayAppend( results_md, "" );
			arrayAppend( results_md, el.errMessage );

			if ( !isEmpty( el.cfmlStackTrace ) ){
				//arrayAppend( results, TAB & TAB & "at", true);
				for ( frame in el.cfmlStackTrace ){
					arrayAppend( results, TAB & TAB & frame );
					if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
						file_ref = replace( frame, server.system.environment.GITHUB_WORKSPACE, "" );
						arrayAppend( results_md,
							"- [#file_ref#](#github_commit_base_href##replace(file_ref,":", "##L")#)"
							& " [branch](#github_branch_base_href##replace(file_ref,":", "##L")#)" );
					}
				}
			}

			if ( !isEmpty( el.StackTrace ) ){
				arrayAppend( results_md, "" );
				arrayAppend( results, NL );
				arrStack = test._testRunner::trimJavaStackTrace( el.StackTrace );
				for (s in arrStack) {
					arrayAppend( results, s );
					arrayAppend( results_md, s );
				}
			}

			arrayAppend( results_md, "" );
			arrayAppend( results, NL );
		}
		arrayAppend( results_md, "" );
		arrayAppend( results, NL );
	}

	if ( len( results ) ) {
		loop array=#results# item="resultLine" {
			systemOutput( resultLine, (resultLine neq NL) );
		}
		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			//systemOutput( server.system.environment.GITHUB_STEP_SUMMARY, true );
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, ArrayToList( results_md, NL ) );
		}
		/*
		loop collection=server.system.environment key="p" value="v" {
			if ( p contains "GITHUB_")
				systemOutput("#p#: #v##NL#");
		*/
	} else if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
		fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "#### Tests Passed :white_check_mark:" );
	}

	if ( ( result.getTotalFail() + result.getTotalError() ) > 0 ) {
		throw "TestBox could not successfully execute all testcases: #result.getTotalFail()# tests failed; #result.getTotalError()# tests errored.";
	}

	if ( ( result.getTotalError() + result.getTotalFail() + result.getTotalPass() ) eq 0 ){
		systemOutput( "", true );
		systemOutput( "ERROR: No tests were run", true );
		systemOutput( "", true );
		throw "ERROR: No tests were run";
	}

	if ( len( new test._setupTestServices().reportServiceFailed() ) gt 0 
			&& new test._setupTestServices().failOnConfiguredServiceError() ) {
		throw "ERROR: test service(s) failed";
	}

} catch( e ){
	systemOutput( "-------------------------------------------------------", true );
	// systemOutput( "Testcase failed:", true );
	systemOutput( e.message, true );
	systemOutput( ReReplace( Serialize( e.stacktrace ), "[\r\n]\s*([\r\n]|\Z)", Chr( 10 ) , "ALL" ), true ); // avoid too much whitespace from dump
	systemOutput( "-------------------------------------------------------", true );
	rethrow;
}

} // if (execute)
</cfscript>
