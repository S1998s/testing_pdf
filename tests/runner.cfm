<cfscript>
  // Ensure TestBox is loaded dynamically
  testbox = new testbox.system.TestBox(
    directory = "/specs/",  // Ensure this resolves correctly
    reporter = "json"
  );

  // Run the tests
  results = testbox.run();

  // Output results
  writeOutput(serializeJSON(results));
</cfscript>
