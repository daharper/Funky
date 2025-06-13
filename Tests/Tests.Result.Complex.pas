{
  This unit tests fluent functional chaining using TResultWrapper<T>.
  Be warned: Delphi will fight you. Hard.
  Proceed only if you're willing to wrestle the compiler.

  Even though it's been demonstrated that FP like fluent chaining is
  possible in Delphi, I caution against introducing such complexity.

  Keep the basic TResult<T>, which is very useful, remove the rest.

  Motto: Use rarerly and responsibly — refactor mercilessly.
}

unit Tests.Result.Complex;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Rtti,
  SharedKernel.Core,
  Mocks.Entities,
  Mocks.Repositories;

type
  [TestFixture]
  TComplexResultTests = class
  private
    fCustomers: TCustomerRepository;
    fSales: TSaleRepository;

    function GetMaxItEarner(const aList: TCustomerList): TCustomer;
    function GetSalesFor(aSection: string):  TResult<TSalesList>;
    function GetTotalSalesFor(aSection: string): TResultWrapper<integer>;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Map_TransformsValue;
    [Test] procedure Bind_ChainsComputation;
    [Test] procedure Apply_WorksWithWrappedFunction;
    [Test] procedure Recover_HandlesError;
    [Test] procedure MapError_TransformsErrorMessage;
    [Test] procedure OrElse_ReturnsFallback;
    [Test] procedure Zip_CombinesTwoSuccessResults;
    [Test] procedure SelectMany_ProjectsCorrectly;
    [Test] procedure Ensure_ValidatesCorrectly;
    [Test] procedure Tap_ExecutesSideEffect;
    [Test] procedure Match_BranchesCorrectly;
    [Test] procedure Find_High_Earning_IT_Person_ReturnsCustomerName;
    [Test] procedure Zip_Sales_From_Two_Sections_ToProductNamePairs;
    [Test] procedure Bind_Combined_Section_Totals;
  end;

implementation

uses
  System.Math;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function TComplexResultTests.GetMaxItEarner(const aList: TCustomerList): TCustomer;
var
  C, MaxC: TCustomer;
begin
  MaxC := Default(TCustomer);

  for C in aList do
    if (C.Department = 'IT') and ((MaxC.Name = '') or (C.Salary > MaxC.Salary)) then
      MaxC := C;

  if MaxC.Name = '' then
    raise Exception.Create('No IT employee found');

  Result := MaxC;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TComplexResultTests.GetSalesFor(aSection: string): TResult<TSalesList>;
begin
  var sales := fSales.Stream
                  .Filter(function(s: TSale): boolean
                    begin
                      Result := s.Section = aSection;
                    end)
                  .ToList;

  Result := TResult<TSalesList>.Ok(sales);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TComplexResultTests.GetTotalSalesFor(aSection: string): TResultWrapper<integer>;
var
  total: Integer;
begin
  total := fSales.Stream
                    .Filter(function(s: TSale): boolean
                      begin
                        Result := s.Section = aSection;
                      end)
                    .Reduce<integer>(0, function(total: integer; s: TSale): integer
                      begin
                        Result := total + s.Price;
                      end);


  Result := TResult.WrapValue(total);
end;

{ TResultTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Bind_Combined_Section_Totals;
var
  lResult: TResult<Integer>;
begin
  lResult :=
    GetTotalSalesFor('Dairy')
      .Bind<Integer>(function(dairy: Integer): TResult<Integer>
        begin
          Result := GetTotalSalesFor('Grains')
            .Map<Integer>(function(grains: Integer): Integer
              begin
                Result := dairy + grains;
              end)
            .Result;
        end)
      .Bind<Integer>(function(dg: Integer): TResult<Integer>
        begin
          Result := GetTotalSalesFor('Drinks')
            .Map<Integer>(function(drinks: Integer): Integer
              begin
                Result := dg + drinks;
              end)
            .Result;
        end)
      .Bind<Integer>(function(dgd: Integer): TResult<Integer>
        begin
          Result := GetTotalSalesFor('Alcohol')
            .Map<Integer>(function(alcohol: Integer): Integer
              begin
                Result := dgd + alcohol;
              end)
            .Result;
        end)
      .Result;

  Assert.IsTrue(lResult.IsOk);
  Assert.AreEqual(575000, lResult.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Find_High_Earning_IT_Person_ReturnsCustomerName;
var
  lResult: TResult<string>;
begin
   lResult :=
    TResult.WrapValue<TCustomerList>(fCustomers.ToList)
      .Map<TCustomer>(function(List: TCustomerList): TCustomer
        begin
          Result := GetMaxItEarner(List);
        end)
      .Map<string>(function(C: TCustomer): string
        begin
          Result := C.Name;
        end).Result;

  Assert.IsTrue(lResult.IsOk);
  Assert.AreEqual('Aidan', lResult.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Zip_Sales_From_Two_Sections_ToProductNamePairs;
var
  lResult:     TResult<TList<string>>;
  lDairySales: TResult<TSalesList>;
  lGrainSales: TResult<TSalesList>;
begin
  lDairySales := GetSalesFor('Dairy');
  lGrainSales := GetSalesFor('Grains');

  lResult :=
    TResult.Wrap<TSalesList>(lDairySales)
      .Zip<TSalesList, TList<string>>(lGrainSales,
        function(DairySales, GrainsSales: TSalesList): TList<string>
        var
          i, Count: Integer;
        begin
          Result := TList<string>.Create;

          Count := Min(DairySales.Count, GrainsSales.Count);

          for i := 0 to Count - 1 do
            Result.Add(DairySales[i].Product + ' / ' + GrainsSales[i].Product);
        end
      ).Result;

  Assert.IsTrue(lResult.IsOk);
  Assert.AreEqual(3, lResult.Value.Count);
  Assert.AreEqual('Milk / Bread', lResult.Value[0]);

  lResult.Value.Free;
  lDairySales.Value.Free;
  lGrainSales.Value.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Map_TransformsValue;
var
  lMapped: TResultWrapper<string>;
  lMapper: TFunc<Integer, string>;
begin
  lMapper := function(i: Integer): string
    begin
      Result := IntToStr(i * 2);
    end;

  lMapped := TResult
              .WrapValue<Integer>(5)
              .Map<string>(lMapper);

  Assert.IsTrue(lMapped.Result.IsOk);
  Assert.AreEqual('10', lMapped.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Bind_ChainsComputation;
var
  lBound: TResultWrapper<Integer>;
begin
  lBound := TResult
              .Wrap<Integer>(TResult<Integer>.Ok(3))
              .Bind<Integer>(function(i: Integer): TResult<Integer>
                begin
                  Result := TResult<Integer>.Ok(i * i);
                end);

  Assert.IsTrue(lBound.Result.IsOk);
  Assert.AreEqual(9, lBound.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Apply_WorksWithWrappedFunction;
var
  lApplied: TResultWrapper<string>;
  lFunc: TFunc<Integer, string>;
  lFuncRes: TResult<TFunc<Integer, string>>;
begin
  lFunc := function(i: Integer): string
    begin
      Result := IntToStr(i * 3);
    end;

  lFuncRes := TResult<TFunc<Integer, string>>.Ok(lFunc);

  lApplied := TResult
                .WrapValue<Integer>(5)
                .Apply<string>(lFuncRes);

  Assert.IsTrue(lApplied.Result.IsOk);
  Assert.AreEqual('15', lApplied.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Recover_HandlesError;
var
  lRecovered: TResultWrapper<Integer>;
  lHandler:   TFunc<string, TResult<Integer>>;
begin
  lHandler := function(msg: string): TResult<Integer>
    begin
      Result := TResult<Integer>.Ok(999);
    end;

  lRecovered := TResult
                  .Wrap<Integer>(TResult<Integer>.Err('fail'))
                  .Recover(lHandler);

  Assert.IsTrue(lRecovered.Result.IsOk);
  Assert.AreEqual(999, lRecovered.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.MapError_TransformsErrorMessage;
var
  lMapped: TResultWrapper<Integer>;
  lMapper: TFunc<string, string>;
begin
  lMapper := function(msg: string): string
    begin
      Result := 'Error: ' + msg;
    end;

  lMapped := TResult
               .Wrap<Integer>(TResult<Integer>.Err('bad'))
               .MapError(lMapper);

  Assert.IsTrue(lMapped.Result.IsErr);
  Assert.AreEqual('Error: bad', lMapped.Result.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.OrElse_ReturnsFallback;
var
  lFinal: TResultWrapper<Integer>;
  lFallback: TResult<Integer>;
begin
  lFallback := TResult<Integer>.Ok(123);

  lFinal := TResult
              .WrapError<Integer>('fail')
              .OrElse(TResult<Integer>.Ok(123));

  Assert.IsTrue(lFinal.Result.IsOk);
  Assert.AreEqual(123, lFinal.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Zip_CombinesTwoSuccessResults;
var
  lZipped: TResultWrapper<string>;
  lOther: TResult<Integer>;
  lCombiner: TFunc<Integer, Integer, string>;
begin
  lOther := TResult<Integer>.Ok(3);

  lCombiner := function(a, b: Integer): string
    begin
      Result := IntToStr(a + b);
    end;

  lZipped := TResult.WrapValue<Integer>(2)
              .Zip<Integer, string>(lOther, lCombiner);

  Assert.IsTrue(lZipped.Result.IsOk);
  Assert.AreEqual('5', lZipped.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.SelectMany_ProjectsCorrectly;
var
  lResulted:  TResultWrapper<string>;
  lBinder:    TFunc<Integer, TResult<string>>;
  lProjector: TFunc<Integer, string, string>;
begin
  lBinder := function(i: Integer): TResult<string>
    begin
      Result := TResult<string>.Ok(IntToStr(i));
    end;

  lProjector := function(i: Integer; s: string): string
    begin
      Result := Format('%d as %s', [i, s]);
    end;

  lResulted := TResult
                 .WrapValue<Integer>(5)
                 .SelectMany<string, string>(lBinder, lProjector);

  Assert.IsTrue(lResulted.Result.IsOk);
  Assert.AreEqual('5 as 5', lResulted.Result.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Ensure_ValidatesCorrectly;
var
  lEnsured:   TResultWrapper<Integer>;
  lPredicate: TPredicate<Integer>;
begin
  lPredicate := function(i: Integer): Boolean
    begin
      Result := i > 5;
    end;

  lEnsured := TResult
                .WrapValue<Integer>(10)
                .Ensure(lPredicate, 'Too small');

  Assert.IsTrue(lEnsured.Result.IsOk);

  lEnsured := TResult
                .WrapValue<Integer>(3)
                .Ensure(lPredicate, 'Too small');

  Assert.IsTrue(lEnsured.Result.IsErr);
  Assert.AreEqual('Too small', lEnsured.Result.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Tap_ExecutesSideEffect;
var
  lCalled:     Boolean;
  lResult:     TResult<Integer>;
  lSideEffect: TProc<Integer>;
begin
  lCalled := False;

  lSideEffect := procedure(i: Integer)
    begin
      lCalled := True;
      Assert.AreEqual(42, i);
    end;

  lResult := TResult
                .WrapValue<Integer>(42)
                .Tap(lSideEffect)
                .Result;

  Assert.IsTrue(lCalled);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Match_BranchesCorrectly;
var
  lOkCalled:  Boolean;
  lErrCalled: Boolean;
  lOnOk:      TProc<Integer>;
  lOnErr:     TProc<string>;
begin
  lOkCalled := False;
  lErrCalled := False;

  lOnOk := procedure(i: Integer)
    begin
      lOkCalled := True;
    end;

  lOnErr := procedure(msg: string)
    begin
      lErrCalled := True;
    end;

  TResult
    .WrapValue<Integer>(123)
    .Match(lOnOk, lOnErr);

  Assert.IsTrue(lOkCalled);
  Assert.IsFalse(lErrCalled);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.Setup;
begin
  fCustomers := TCustomerRepository.Create;
  fSales := TSaleRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TComplexResultTests.TearDown;
begin
  fCustomers.Free;
  fSales.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TComplexResultTests);

end.

