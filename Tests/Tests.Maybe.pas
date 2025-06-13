unit Tests.Maybe;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections;

type
  [TestFixture]
  TMaybeTests = class
  public
    [Test] procedure Maybe_Some_HasValue;
    [Test] procedure Maybe_None_HasNoValue;
    [Test] procedure Maybe_OrElse_ReturnsValueWhenNone;
    [Test] procedure Maybe_OrElse_ReturnsValueWhenSome;
    [Test] procedure Maybe_OrElseGet_EvaluatesFunctionOnlyIfNone;
    [Test] procedure Maybe_OrElseGet_DoesNotEvaluateFunctionIfSome;
  end;

implementation

uses
  SharedKernel.Core;

{ TMaybeTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_Some_HasValue;
var
  m: TMaybe<Integer>;
begin
  m := TMaybe<Integer>.Some(42);

  Assert.IsTrue(m.IsSome, 'Expected IsSome to be True');
  Assert.IsFalse(m.IsNone, 'Expected IsNone to be False');
  Assert.AreEqual(42, m.Value, 'Expected stored value to be 42');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_None_HasNoValue;
var
  m: TMaybe<Integer>;
begin
  m := TMaybe<Integer>.None;

  Assert.IsFalse(m.IsSome, 'Expected IsSome to be False');
  Assert.IsTrue(m.IsNone, 'Expected IsNone to be True');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_OrElse_ReturnsValueWhenNone;
var
  m: TMaybe<Integer>;
begin
  m := TMaybe<Integer>.None;
  Assert.AreEqual(99, m.OrElse(99), 'Expected fallback value to be returned');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_OrElse_ReturnsValueWhenSome;
var
  m: TMaybe<Integer>;
begin
  m := TMaybe<Integer>.Some(10);
  Assert.AreEqual(10, m.OrElse(99), 'Expected original value to be returned');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_OrElseGet_EvaluatesFunctionOnlyIfNone;
var
  m: TMaybe<Integer>;
  evaluated: Boolean;
begin
  evaluated := False;

  m := TMaybe<Integer>.None;

  Assert.AreEqual(123, m.OrElseGet(
    function: Integer
    begin
      evaluated := True;
      Result := 123;
    end));

  Assert.IsTrue(evaluated, 'Expected fallback function to be evaluated');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeTests.Maybe_OrElseGet_DoesNotEvaluateFunctionIfSome;
var
  m: TMaybe<Integer>;
  evaluated: Boolean;
begin
  evaluated := False;

  m := TMaybe<Integer>.Some(7);

  Assert.AreEqual(7, m.OrElseGet(
    function: Integer
    begin
      evaluated := True;
      Result := 999;
    end));

  Assert.IsFalse(evaluated, 'Expected fallback function to not be evaluated');
end;

initialization
  TDUnitX.RegisterTestFixture(TMaybeTests);

end.

