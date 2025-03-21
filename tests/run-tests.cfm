<cfscript>

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
	
	// this isn't used ???
	fixCase = {};
	for (el in ["bundleId", "debugBuffer", "endTime", "error", "failMessage", "failOrigin", "globalException", "name", "parentId", "path", "specStats",
		"startTime", "status", "suiteId", "suiteStats", "totalDuration", "totalError", "totalFail", "totalPass", "totalSkipped", "totalSpecs", "totalSuites"]) {
		fixCase[ucase(el)] = el;
	}
	
	systemOutput("Running tests with Java: #server.java.version# (Compiler: #server.java.javaCompilerVersion?:'unknown'#)", true);
	
	try {
	
		// create "/test" mapping
		admin
			action="updateMapping"
			type="web"
			password="#request.WEBADMINPASSWORD#"
			virtual="/test"
			physical="#request.testFolder#"
			toplevel="true"
			archive=""
			primary="physical"
			trusted="no";
	
		admin
			action="updateMapping"
			type="web"
			password="#request.WEBADMINPASSWORD#"
			virtual="/test-once"
			physical="#request.testFolder#"
			toplevel="true"
			archive=""
			primary="physical"
			trusted="no"
			inspect="once";
		
		admin
			action="updateMapping"
			type="web"
			password="#request.WEBADMINPASSWORD#"
			virtual="/test-never"
			physical="#request.testFolder#"
			toplevel="true"
			archive=""
			primary="physical"
			trusted="no"
			inspect="never";
	
		systemOutput("set /test mapping #dateTimeFormat(now())#", true);
	
		param name="testDebug" default="false";
		if ( len( testDebug ) eq 0 )
			testDebug = false;
		request.testDebug = testDebug;
		if ( request.testDebug )
			SystemOutput( "Test Debugging enabled", true );
	
		param name="testServices" default="";
		request.testServices = testServices;
		if ( len( request.testServices ) )
			SystemOutput( "Test Services restricted to [#request.testServices#]", true );
	
		struct function reportMem( string type, struct prev={}, string name="" ) {
			var qry = getMemoryUsage( type );
			var report = [];
			var used = { name: arguments.name };
			querySort(qry,"type,name");
			loop query=qry {
				if (qry.max == -1)
					var perc = 0;
				else 
					var perc = int( ( qry.used / qry.max ) * 100 );
				//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
				//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
				var rpt = replace(ucFirst(qry.type), '_', ' ')
					& " " & qry.name & ": " & numberFormat(perc) & "%, " & numberFormat( qry.used / 1024 / 1024 ) & " Mb";
				if ( structKeyExists( arguments.prev, qry.name ) ) {
					var change = numberFormat( (qry.used - arguments.prev[ qry.name ] ) / 1024 / 1024 );
					if ( change gt 0 ) {
						rpt &= ", (+ " & change & "Mb )";
					} else if ( change lt 0 ) {
						rpt &= ", ( " & change & "Mb )";
					}
				}
				arrayAppend( report, rpt );
				used[ qry.name ] = qry.used;
			}
			return {
				report: report,
				usage: used
			};
		}
	
		// report current memory usage
		_reportMemStat = reportMem( "", {}, "bootup" );
		//for ( stat in _reportMemStat.report )
		//	systemOutput( stat, true );
	
		// you can also provide a json file with your environment variables, i.e. just set LUCEE_BUILD_ENV="c:\work\lucee\loader\env.json"
		setupTestServices = new test._setupTestServices().setup();
	
		// set a password for the admin
		try {
			admin
				action="updatePassword"
				type="web"
				oldPassword=""
				newPassword="#request.WEBADMINPASSWORD#";
		}
		catch(e){}	// may exist from previous execution
	
		try {
			admin
				action="updatePassword"
				type="server"
				oldPassword=""
				newPassword="#request.SERVERADMINPASSWORD#";
		}
		catch(e){}	// may exist from previous execution
	
		systemOutput( "set admin password #dateTimeFormat(now())#", true );
	
		systemOutput("-------------- Test Filters and Labels", true);
	
		param name="testFilter" default="";
		request.testFilter = testFilter;
	
		if ( len( request.testFilter ) eq 0 ){
			request.testFilter = server._getSystemPropOrEnvVars("testFilter", "", false);
			if ( structCount( request.testFilter ) )
				request.testFilter = request.testFilter.testFilter;
			else
				request.testFilter="";
		}
		request.testFilter = ListToArray( trim( request.testFilter ) );
		if ( Arraylen( request.testFilter ) gt 0 )
			systemOutput( NL & "Filtering only tests with filenames containing: " & request.testFilter.toJson() & NL, true );
		else
			systemOutput( NL & 'Running all tests, to run a subset of test(s) by FILENAME, use the parameter -DtestFilter="image,orm,etc"', true );
	
		param name="testLabels" default="";
		request.testLabels = testLabels;
		if ( len( trim( request.testLabels ) ) eq 0){
			request.testLabels = server._getSystemPropOrEnvVars( "testLabels", "", false);
			if ( structCount( request.testLabels ) )
				request.testLabels = request.testLabels.testLabels;
			else
				request.testLabels="";
		}
		request.testLabels = ListToArray( trim( request.testLabels ) );
		if ( ArrayLen( request.testLabels ) )
			SystemOutput( "Filtering tests with the following label(s): #request.testLabels.toJson()#", true );
		else
			systemOutput( NL & 'Running all tests, to run a subset of test(s) by LABEL, use the parameter -DtestLabels="s3,oracle"', true );
	
	
		param name="testSkip" default="true";
		if ( len(testSkip) eq 0)
			testSkip = true;
		request.testSkip = testSkip;
	
		if ( !request.testSkip )
			SystemOutput( "Force running tests marked skip=true or prefixed with an _", true );
	
		param name="testRandomSort" default="false";
		if ( len(testRandomSort) eq 0)
			testRandomSort = false;
		request.testRandomSort = testRandomSort;
	
		// allow using other/additional BaseSpecs like testbox.system.BaseSpec
		param name="testSuiteExtends" default="";
		if ( len( testSuiteExtends ) eq 0 )
			request.testSuiteExtends= "org.lucee.cfml.test.LuceeTestCase";
		else
			request.testSuiteExtends = testSuiteExtends; 
		if ( request.testSuiteExtends != "org.lucee.cfml.test.LuceeTestCase" )
			SystemOutput( "Running with custom BaseSpec [#testSuiteExtends#]", true );
	
		param name="testDebugAbort" default="false";
		if ( len( testDebugAbort ) and testDebugAbort) {
			request.testDebugAbort = true;
		} else {
			request.testDebugAbort = false;
		}
	
		// i.e ant -DtestRandomSort="3" -DtestLabels="image"
	
		if ( request.testRandomSort neq "false" ){
			if ( isNumeric( request.testRandomSort ) ){
				SystemOutput( "Using a randomized sort order for tests, randomize seed [#request.testRandomSort#]", true );
			} else {
				SystemOutput( "Using a random sort order for tests", true );
			}
		}
	
		param name="testAdditional" default="";
		request.testAdditional = testAdditional;
	
		if ( len( request.testAdditional ) eq 0 ){
			request.testAdditional = server._getSystemPropOrEnvVars("testAdditional", "", false);
			if ( structCount( request.testAdditional ) )
				request.testAdditional = request.testAdditional.testAdditional;
			else
				request.testAdditional="";
		}
		if ( len(request.testAdditional) ){
			SystemOutput( "Adding additional tests from [#request.testAdditional#]", true );
			if (!DirectoryExists( request.testAdditional )){
				SystemOutput( "ERROR directory [#request.testAdditional#] doesn't exist!", true );
				request.testAdditional = "";
			} else {
				admin
					action="updateMapping"
					type="web"
					password="#request.WEBADMINPASSWORD#"
					virtual="/testAdditional"
					physical="#request.testAdditional#"
					toplevel="true"
					archive=""
					primary="physical"
					trusted="no";
			}
		}
	
		// output deploy log
		pc = getPageContext();
		config = pc.getConfig();
		configDir = config.getConfigServerDir();
		logsDir = configDir & server.separator.file & "logs";
		deployLog = logsDir & server.separator.file & "deploy.log";
		//dump(deployLog);
		if ( fileExists( deployLog ) )
			content = fileRead( deployLog );
		else
			content = "deploy.log not found, is logging redirected to console?";
	
		systemOutput("-------------- Deploy.Log ------------",true);
		systemOutput( content, true );
		systemOutput("--------------------------------------",true);
	
		// set the testbox mapping
		application
			action="update"
			componentpaths = "#[{archive:testboxArchive}]#";
	
		systemOutput( "update componentpaths #dateTimeFormat( now() )#" & NL, true );
	
		// load testbox
		SystemOut = createObject( "java", "lucee.commons.lang.SystemOut" );
		out = SystemOut.setOut( nullValue() );
		//err = SystemOut.setErr( nullValue() );
	
		request._tick = getTickCount();
		request.overhead = [];
	
		admin
			action="getMappings"
			type="web"
			password="#request.WEBADMINPASSWORD#"
			returnVariable="mappings";
	
		systemOutput("-------------- Mappings --------------", true);
		loop query="mappings" {
			systemOutput("#mappings.virtual# #TAB# #mappings.strPhysical# "
				& (len(mappings.strArchive) ? "[#mappings.strArchive#] " : "")
				& (len(mappings.inspect) ? "(#mappings.inspect#)" : ""), true);
		}
	
		//systemOutput("-------------- Memory after services configured", true);
		_reportMemStat2 = reportMem( "", _reportMemStat.usage, "configured" );
		//for ( stat in _reportMemStat2.report )
		//	systemOutput( stat, true );
	
		systemOutput(NL & "-------------- Start Tests -----------", true);
		silent {
			testResults = new test._testRunner().runTests();
		}
	
	
		result = testResults.result;
		failedTestcases = testResults.failedTestcases;
		tb = testResults.tb;
	
		jUnitReporter = new testbox.system.reports.JUnitReporter();
		resultPath = ExpandPath( "/test" ) & "/reports/";
		if ( !DirectoryExists( resultPath ) )
			DirectoryCreate( resultPath );
		JUnitReportFile = resultPath & "junit-test-results-#server.lucee.version#.xml";
		FileWrite( JUnitReportFile, jUnitReporter.runReport( results=result, testbox=tb, justReturn=true ) );
	
		// load errors into an array, so we can dump them out to $GITHUB_STEP_SUMMARY
		results = [];
		results_md = ["## Lucee #server.lucee.version#", ""];
	
		systemOutput( NL & NL & "=============================================================", true );
		arrayAppend( results, "Lucee Version: #server.lucee.version#");
		arrayAppend( results, "Java Version: #server.java.version#");
		arrayAppend( results, "Java Compiler Version: #server.java.javaCompilerVersion?:'unknown'#");
		arrayAppend( results, "TestBox Version: #tb.getVersion()#");
		arrayAppend( results, "Total Execution time: (#NumberFormat( ( getTickCount()-request._start) / 1000 )# s)");
		arrayAppend( results, "Test Execution time: (#NumberFormat( result.getTotalDuration() /1000 )# s)");
		arrayAppend( results, "Average Test Overhead: (#NumberFormat( ArrayAvg( request.overhead ) )# ms)");
		arrayAppend( results, "Total Test Overhead: (#NumberFormat( ArraySum( request.overhead ) )# ms)");
		ManagementFactoryError = false;
		try {
			arrayAppend( results, "CFTHREADS: #NumberFormat( ThreadData().len() )#");
			javaManagementFactory = createObject( "java", "java.lang.management.ManagementFactory" );
			threadCount = javaManagementFactory.getThreadMXBean().getThreadCount();
			arrayAppend( results, "Active Threads: #NumberFormat( threadCount )#");
		} catch (e) {
			arrayAppend( results, "ERROR getting thread count: #e.message#"); // backwards compat for lucee 6.0
			ManagementFactoryError = true;
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
	
