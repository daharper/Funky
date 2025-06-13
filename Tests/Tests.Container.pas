unit Tests.Container;

interface

uses
  DUnitX.TestFramework,
  SharedKernel.Containers,
  Mocks.Entities,
  Mocks.Repositories,
  Mocks.Services;

type
  [TestFixture]
  TContainerTest = class
  private
    fContainer: TContainer;

  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Should_Register_and_Resolve_Transient;
    [Test] procedure Should_Resolve_Transient;
    [Test] procedure Should_Register_and_Resolve_Singleton;
    [Test] procedure Should_Resolve_Singleton;
    [Test] procedure Should_Resolve_No_Instance_Singleton;
    [Test] procedure Should_Inject_Dependencies_via_Constructor;
  end;

implementation

{ TContainerTest }

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Setup;
begin
  fContainer := TContainer.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.TearDown;
begin
  fContainer.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Resolve_Transient;
var
  lInstance: ISaleRepository;
begin
  lInstance := fContainer.Get<ISaleRepository>;

  Assert.IsTrue(lInstance.Id > 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Register_and_Resolve_Transient;
var
  lInstance: ISaleRepository;
begin
  fContainer.Add<ISaleRepository, TSaleRepository>;

  lInstance := fContainer.Get<ISaleRepository>;

  Assert.IsTrue(lInstance.Id > 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Resolve_No_Instance_Singleton;
var
  lInstance: ICustomerRepository;
begin
  fContainer.AddSingleton<ICustomerRepository, TCustomerRepository>;

  lInstance := fContainer.Get<ICustomerRepository>;

  Assert.IsTrue(lInstance.Id > 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Resolve_Singleton;
var
  lInstance: ICustomerRepository;
begin
  lInstance := fContainer.Get<ICustomerRepository>;

  Assert.IsTrue(lInstance.Id > 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Inject_Dependencies_via_Constructor;
var
  lService: ISaleService;
  lIsPorche: boolean;
  lIsMilk: boolean;
begin
  lService := fContainer.Get<ISaleService>;

  lIsPorche := lService
    .Stream
    .AnyMatch(function(s:TSale): boolean begin Result := s.Product = 'Porche'; end);

  lIsMilk := lService
    .Stream
    .AnyMatch(function(s:TSale): boolean begin Result := s.Product = 'Milk'; end);

  Assert.IsTrue(lIsPorche);
  Assert.IsTrue(lIsMilk);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainerTest.Should_Register_and_Resolve_Singleton;
var
  lInstance: TCustomerRepository;
begin
  lInstance := TCustomerRepository.Create;

  fContainer.AddSingleton<ICustomerRepository, TCustomerRepository>(lInstance);

  var instance := fContainer.Get<ICustomerRepository>;

  Assert.AreEqual(lInstance.Id, instance.Id);
end;

{----------------------------------------------------------------------------------------------------------------------}
initialization
  TDUnitX.RegisterTestFixture(TContainerTest);

end.
