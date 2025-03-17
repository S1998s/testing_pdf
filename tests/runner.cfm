<cfscript>
  // Load TestBox
  include "../testbox/system/TestBox.cfc";

  // Create a new TestBox runner
  runner = new testbox.system.TestBox(
    directory = expandPath("/specs/"),
    reporter = "console"
  );

  // Run the tests
  runner.run();
</cfscript>
