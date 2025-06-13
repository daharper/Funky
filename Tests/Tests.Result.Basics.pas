unit Tests.Result.Basics;

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
  TResultBasicsTests = class
  private
    fCustomers: TCustomerRepository;
    fSales: TSaleRepository;

    function GetMaxSectionEarner(const aSection: string; const aList: TCustomerList): TResult<TCustomer>;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Ok_ConstructsSuccess;
    [Test] procedure Err_ConstructsError;
    [Test] procedure IsOk_IsErr_BehavesCorrectly;
    [Test] procedure IsOk_IsErr_FetchTest;
  end;

implementation

uses
  System.Math;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function TResultBasicsTests.GetMaxSectionEarner(const aSection: string; const aList: TCustomerList): TResult<TCustomer>;
var
  C, MaxC: TCustomer;
begin
  MaxC := Default(TCustomer);

  for C in aList do
    if (C.Department = aSection) and ((MaxC.Name = '') or (C.Salary > MaxC.Salary)) then
      MaxC := C;

  if MaxC.Name = '' then
    Result := TResult<TCustomer>.Err('No section employee found')
  else
    Result := TResult<TCustomer>.Ok(MaxC);
end;

{ TResultTests }


{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.Ok_ConstructsSuccess;
var
  lRes: TResult<Integer>;
begin
  lRes := TResult<Integer>.Ok(42);

  Assert.IsTrue(lRes.IsOk);
  Assert.AreEqual(42, lRes.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.Err_ConstructsError;
var
  lRes: TResult<Integer>;
begin
  lRes := TResult<Integer>.Err('Something went wrong');

  Assert.IsTrue(lRes.IsErr);
  Assert.AreEqual('Something went wrong', lRes.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.IsOk_IsErr_BehavesCorrectly;
var
  lResOk,
  lResErr: TResult<Integer>;
begin
  lResOk  := TResult<Integer>.Ok(1);
  lResErr := TResult<Integer>.Err('fail');

  Assert.IsTrue(lResOk.IsOk);
  Assert.IsFalse(lResOk.IsErr);
  Assert.IsFalse(lResErr.IsOk);
  Assert.IsTrue(lResErr.IsErr);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.IsOk_IsErr_FetchTest;
var
  lResOk:     TResult<TCustomer>;
  lResErr:    TResult<TCustomer>;
  lCustomers: TCustomerList;
begin
  lCustomers := fCustomers.ToList;

  lResOk  := GetMaxSectionEarner('IT', lCustomers);

  lResErr := GetMaxSectionEarner('@', lCustomers);

  Assert.IsTrue(lResOk.IsOk);
  Assert.IsTrue(lResErr.IsErr);

  Assert.AreEqual('Aidan', lResOk.Value.Name);
end;


{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.Setup;
begin
  fCustomers := TCustomerRepository.Create;
  fSales := TSaleRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultBasicsTests.TearDown;
begin
  fCustomers.Free;
  fSales.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TResultBasicsTests);

end.

