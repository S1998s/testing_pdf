<cfscript>
  // Ensure TestBox is loaded dynamically
	testbox = new testbox.system.TestBox(
		directory = "/specs/",
		reporter = "json"
	);

	  // Run the tests
	 results = testbox.run();
	
	  // Output results
	  // writedump(serializeJSON(results));
	writedump(results);
 </cfscript>
