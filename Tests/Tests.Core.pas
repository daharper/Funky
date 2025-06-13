{
  Tests for a couple of classes left in the Core unit
}

unit Tests.Core;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections;

type
  [TestFixture]
  TCoreTests = class
  public
    [Test] procedure Scope_Test;
    [Test] procedure Use_WithTResult_CallsFunctionAndCleansUp;
    [Test] procedure Use_WithTMaybe_CallsFunctionAndCleansUp;
    [Test] procedure Lazy_EvaluatesOnlyOnceAndCachesResult;
  end;

  TLanguage = class
  private
    fName: string;
  public
    property Name: string read fName write fName;

    constructor Create(aName: string);
  end;

implementation

uses
  SharedKernel.Core;

{ TCoreTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TCoreTests.Scope_Test;
var
  scope: TScope;
begin
  var delphi  := scope.Add(TLanguage.Create('Delphi'));
  var csharp  := scope.Add(TLanguage.Create('CSharp'));
  var flutter := scope.Add(TLanguage.Create('Flutter'));
  var rust    := scope.Add(TLanguage.Create('Rust'));

  Assert.AreEqual('Delphi', delphi.Name);
  Assert.AreEqual('CSharp', csharp.Name);
  Assert.AreEqual('Flutter', flutter.Name);
  Assert.AreEqual('Rust', rust.Name);

  { memory leak reporting is on, shouldn't throw a leak error }
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCoreTests.Use_WithTResult_CallsFunctionAndCleansUp;
var
  Result: TResult<string>;
begin
  Result := TUse<TLanguage>.Exec<string>(TLanguage.Create('Delphi'),
    function(Lang: TLanguage): TResult<string>
    begin
      Result := TResult<string>.Ok(Lang.Name);
    end).Result;

  Assert.IsTrue(Result.IsOk);
  Assert.AreEqual('Delphi', Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCoreTests.Use_WithTMaybe_CallsFunctionAndCleansUp;
var
  Maybe: TMaybe<string>;
begin
  Maybe := TUse<TLanguage>.Exec<string>(TLanguage.Create('Pascal'),
    function(Lang: TLanguage): TMaybe<string>
    begin
      Result := TMaybe<string>.Some(Lang.Name);
    end);

  Assert.IsTrue(Maybe.IsSome);
  Assert.AreEqual('Pascal', Maybe.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCoreTests.Lazy_EvaluatesOnlyOnceAndCachesResult;
var
  counter: Integer;
  lazy: TLazy<Integer>;
  val1, val2: Integer;
begin
  counter := 0;

  lazy := TLazy<Integer>.Create(
    function: Integer
    begin
      Inc(counter);
      Result := 123;
    end
  );

  Assert.IsFalse(lazy.IsEvaluated, 'Expected IsEvaluated to be False initially');

  val1 := lazy.Value;
  Assert.AreEqual(123, val1);
  Assert.IsTrue(lazy.IsEvaluated, 'Expected IsEvaluated to be True after evaluation');
  Assert.AreEqual(1, counter, 'Expected function to have been evaluated once');

  val2 := lazy.Value;
  Assert.AreEqual(123, val2);
  Assert.AreEqual(1, counter, 'Expected no re-evaluation');

  lazy.Reset;
  Assert.IsFalse(lazy.IsEvaluated, 'Expected IsEvaluated to be False after Reset');

  val1 := lazy.Value;
  Assert.AreEqual(123, val1);
  Assert.AreEqual(2, counter, 'Expected function to be re-evaluated once after Reset');
end;

{ TLanguage }

{----------------------------------------------------------------------------------------------------------------------}
constructor TLanguage.Create(aName: string);
begin
  fName := aName;
end;

initialization
  TDUnitX.RegisterTestFixture(TCoreTests);

end.

