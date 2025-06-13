unit Tests.Specifications;

interface

uses
  DUnitX.TestFramework,
  SharedKernel.Specifications,
  Mocks.Entities,
  Mocks.Repositories;

type
  [TestFixture]
  TSpecificationTests = class
  private
    fCustomers: TCustomerRepository;
    fSales: TSaleRepository;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ITCustomerWithHighSalary_ReturnsMatches;
    [Test] procedure DairyOrAlcoholSales_ContainsExpectedProducts;
    [Test] procedure NotITCustomer_ReturnsNonIT;
  end;

  TDepartmentIs = class(TSpecification<TCustomer>)
  private
    fDept: string;
  public
    constructor Create(const Dept: string);
    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;
  end;

  TSalaryAbove = class(TSpecification<TCustomer>)
  private
    fThreshold: Integer;
  public
    constructor Create(Threshold: Integer);
    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;
  end;

  TSaleSectionIs = class(TSpecification<TSale>)
  private
    fSection: string;
  public
    constructor Create(const Section: string);
    function IsSatisfiedBy(const Candidate: TSale): Boolean; override;
  end;

implementation

{$region 'specifications'}

{----------------------------------------------------------------------------------------------------------------------}
constructor TDepartmentIs.Create(const Dept: string);
begin
  inherited Create;
  fDept := Dept;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDepartmentIs.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
begin
  Result := Candidate.Department = fDept;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSalaryAbove.Create(Threshold: Integer);
begin
  inherited Create;
  fThreshold := Threshold;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSalaryAbove.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
begin
  Result := Candidate.Salary > fThreshold;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSaleSectionIs.Create(const Section: string);
begin
  inherited Create;
  fSection := Section;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleSectionIs.IsSatisfiedBy(const Candidate: TSale): Boolean;
begin
  Result := Candidate.Section = fSection;
end;

{$endregion}

{ TSpecificationTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.ITCustomerWithHighSalary_ReturnsMatches;
var
  spec: ISpecification<TCustomer>;
  c: TCustomer;
  matches: TArray<string>;
begin
  spec := TDepartmentIs.Create('IT').AndAlso(TSalaryAbove.Create(68000));

  for c in fCustomers do
    if spec.IsSatisfiedBy(c) then
      matches := matches + [c.Name];

  Assert.Contains<string>(matches, 'Aidan');
  Assert.Contains<string>(matches, 'Slim');
  Assert.DoesNotContain<string>(matches, 'Eduardo');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.DairyOrAlcoholSales_ContainsExpectedProducts;
var
  spec: ISpecification<TSale>;
  s: TSale;
  matches: TArray<string>;
begin
  spec := TSaleSectionIs.Create('Dairy').OrElse(TSaleSectionIs.Create('Alcohol'));

  for s in fSales do
    if spec.IsSatisfiedBy(s) then
      matches := matches + [s.Product];

  Assert.Contains<string>(matches, 'Milk');
  Assert.Contains<string>(matches, 'Guiness');
  Assert.DoesNotContain<string>(matches, 'Pasta');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.NotITCustomer_ReturnsNonIT;
var
  spec: ISpecification<TCustomer>;
  c: TCustomer;
  matches: TArray<string>;
begin
  spec := TDepartmentIs.Create('IT').NotThis;

  for c in fCustomers do
    if spec.IsSatisfiedBy(c) then
      matches := matches + [c.Name];

  Assert.Contains<string>(matches, 'Paul');
  Assert.Contains<string>(matches, 'Una');
  Assert.DoesNotContain<string>(matches, 'Aidan');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.Setup;
begin
  fCustomers := TCustomerRepository.Create;
  fSales := TSaleRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.TearDown;
begin
  fCustomers.Free;
  fSales.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TSpecificationTests);

end.

