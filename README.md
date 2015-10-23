Babel Test Harness
==================

Babel test harness is a simple static web framework built on backbone that allows developers to functionally test their Http/Json services
without having to use client code.

### Build
NOTE!! - Currently builds can only be done on a unix based OS.

Gradle tasks are provided for this project and can be run from the root project directory.  The main tasks are:

	gradle build - produces a zip file containing the testharness.
	gradle install - build the zip file, and publishes it to the local maven repository.

Builds also get sync'ed to the java babel example application under this project for easy functional testing when making changes.

### Configure using gradle

1.  The version of the test harness used by a project is determined by the 'version' property in the 'babel' configuration. 
2.  (Optional) For each of your 'tests' configuration sections, add a 'testHarnessDir' property to indicate where the test harness should be unpacked to.
3.  Running either the babelUpdateDependencies or babelGenerate tasks will update the test harness in the directories configured.
