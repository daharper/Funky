program Funky;

{$DEFINE TESTINSIGHT}

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.TestFramework,
  Tests.Stream in 'Tests\Tests.Stream.pas',
  SharedKernel.Specifications in 'SharedKernel.Specifications.pas',
  SharedKernel.Containers in 'SharedKernel.Containers.pas',
  SharedKernel.Core in 'SharedKernel.Core.pas',
  SharedKernel.Streams in 'SharedKernel.Streams.pas',
  Mocks.Entities in 'Tests\Mocks\Mocks.Entities.pas',
  Mocks.Repositories in 'Tests\Mocks\Mocks.Repositories.pas',
  Mocks.Services in 'Tests\Mocks\Mocks.Services.pas',
  Tests.Container in 'Tests\Tests.Container.pas',
  Tests.Result.Complex in 'Tests\Tests.Result.Complex.pas',
  Tests.Maybe in 'Tests\Tests.Maybe.pas',
  Tests.Result.Basics in 'Tests\Tests.Result.Basics.pas',
  Tests.Core in 'Tests\Tests.Core.pas',
  Tests.Specifications in 'Tests\Tests.Specifications.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
  ReportMemoryLeaksOnShutdown := true;

{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
