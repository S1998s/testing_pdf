<cfscript>
  // Load TestBox
  include "../testbox/system/TestBox.cfc";

  // Create a new TestBox runner
  runner = new testbox.system.TestBox(
    directory = expandPath("/specs/"),
    reporter = "console"
  );

  writeDump(runner);
  // Run the tests
  results = runner.run();

  // Output the results
  writeOutput(results);
</cfscript>
