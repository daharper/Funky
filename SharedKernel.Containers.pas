unit SharedKernel.Containers;

interface

uses
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  SharedKernel.Core;

type

  /// <summary>
  /// Provides a basic DI Container. Initially tried to build it similar to
  /// containers I've built in other languages, but quickly hit limitations
  /// in the RTTI system, and my knowledge. It is effective, but really
  /// needs reworking now I understand more.
  ///
  /// Essentially it distinguishes between two types: TSingleton, and TTransient.
  /// I didn't want the user to worry about memory management, and I especially
  /// didn't want them to accidentally free a Singleton indirectly. TTransient
  /// types are reference counted. They will clean up automatically. TSingleton
  /// is not reference counted, and is managed by the container.
  ///
  /// Because interfaces are used to manage memory, all types must be registered
  /// against an interface. This was an acceptable limitation for my use case,
  /// but something to reconsider in the future.
  ///
  /// To improve performance, types and interfaces are filtered and cached
  /// during initialization.
  /// </summary>
  /// <example>
  ///
  /// Example registration from a current project in development:
  ///
  ///  Container.AddServices([
  ///    TGameSession,
  ///    TWorldBuilder,
  ///    TWorldEngine,
  ///    TClassificationProfile,
  ///    TTextParser,
  ///    TConsole,
  ///    TConsolePlayerPresenter,
  ///    TConsoleWorldPresenter
  ///  ]);
  ///
  /// Example service receiving injection via constructors:
  ///
  /// constructor TConsole.Create(
  ///   aParser: ITextParser;
  ///   aPlayerPresenter: IPlayerPresenter;
  ///   aWorldPresenter: IWorldPresenter;
  ///   aStartGameUseCase: IStartGameUseCase;
  ///   aDispatcher: ICommandDispatcher;
  ///   aWorldEngine: IWorldEngine);
  ///
  /// <example>
  TContainer = class
  private
    fContext:      TRttiContext;
    fCache:        TList<TRttiType>;
    fProviders:    TDictionary<TGuid, TRttiType>;
    fSingletons:   TObjectDictionary<TGuid, TObject>;
    fInterfaceMap: TDictionary<TGUID, TRttiType>;

    function RegisterType<TService, TProvider>: TGuid;
    function Resolve(const [ref] aType: TRttiType): TValue;
    function ClassImplements<TService>(AClass: TClass): Boolean;
    function AllParamsAreInterfaces(const [ref] aMethod: TRttiMethod): boolean;

    procedure Initialize;
  public
    function Get<TService:IInterface>: TService; overload;
    function Get<TService:IInterface>(aGuid: TGuid): TService; overload;
    function Get<TService:IInterface>(aClass: TClass): TService; overload;

    procedure AddSingleton<TService:IInterface; TProvider:TSingleton>; overload;
    procedure AddSingleton<TService:IInterface; TProvider:TSingleton>(aInstance: TProvider); overload;
    procedure Add<TService: IInterface; TProvider:TTransient>;
    procedure AddService(aInterfaceGuid: TGuid; aProvider:TClass);
    procedure AddServices(aServices: array of TClass);
    procedure RemoveSingleton<TService:IInterface>; overload;

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  /// A singleton container, used for the universal application container.
  /// </summary>
  TSingleContainer = class
  class var
    fInstance: TContainer;
  public
    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  /// Global function providing simple access to the universal container.
  /// </summary>
  function Container: TContainer;

implementation

uses
  System.StrUtils,
  System.SysUtils,
  System.Variants,
  System.Generics.Defaults,
  SharedKernel.Streams;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function Container: TContainer;
begin
  Result := TSingleContainer.fInstance;
end;

{ TContainer }

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.RegisterType<TService, TProvider>: TGuid;
var
  lType: TRttiType;
  lGuid: TGuid;
begin
  lType := fContext.GetType(TypeInfo(TService));
  lGuid := GetTypeData(lType.Handle)^.Guid;
  lType := fContext.GetType(TypeInfo(TProvider));

  fProviders.AddOrSetValue(lGuid, lType);

  Result := lGuid;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Initialize;
var
  lType: TRttiType;
  lRttiClass: TRttiInstanceType;
  lClass: TClass;
begin
  for lType in fContext.GetTypes do
  begin
    { build up interface map }
    if lType is TRttiInterfaceType then
    begin
      { TODO -oDavid -cTechnical Debt : Improve namespace filtering and make argument based }
      if not ((lType is TRttiInterfaceType) and
             ((lType.QualifiedName.StartsWith('Domain.') or
             (lType.QualifiedName.StartsWith('Application.'))))) then continue;

      fInterfaceMap.AddOrSetValue(TRttiInterfaceType(lType).GUID, lType);
      continue;
    end;

    if lType.TypeKind <> tkClass then continue;
    if not (lType is TRttiInstanceType) then continue;

    { build up class cache }
    lRttiClass := TRttiInstanceType(lType);
    lClass := lRttiClass.MetaclassType;

    if lClass.ClassNameIs('TSingleton') or lClass.ClassNameIs('TTransient') then continue;

    if lClass.InheritsFrom(TTransient) or lClass.InheritsFrom(TSingleton) then
    begin
      fCache.Add(lType);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.RemoveSingleton<TService>;
var
  lType: TRttiType;
  lGuid: TGuid;
begin
  lType := fContext.GetType(TypeInfo(TService));
  lGuid := GetTypeData(lType.Handle)^.Guid;

  if not fSingletons.ContainsKey(lGuid) then exit;

  if Assigned(fSingletons[lGuid]) then
    fSingletons[lGuid].Free;

  fSingletons.Remove(lGUid);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Add<TService, TProvider>;
begin
  RegisterType<TService, TProvider>;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddSingleton<TService, TProvider>;
const
  ALREADY_REGISTERED = 'singleton has already been registered';
var
  lGuid: TGuid;
begin
  lGuid := RegisterType<TService, TProvider>;

  Expect.IsFalse(fSingletons.ContainsKey(lGuid), ALREADY_REGISTERED);

  fSingletons.Add(lGuid, nil);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddService(aInterfaceGuid: TGuid; aProvider: TClass);
const
  REG_ERROR = 'Service has already been registered: %s';
  SINGLETON_ERROR = 'A singleton exists for this service, unable to register: %s';
var
  lType: TRTTIType;
begin
  lType := fContext.GetType(aProvider);

  Expect.IsFalse(fProviders.ContainsKey(aInterfaceGuid), Format(REG_ERROR, [aProvider.ClassName]));

  if ClassImplements<TSingleton>(aProvider) then
  begin
    Expect.IsFalse(fSingletons.ContainsKey(aInterfaceGuid), Format(SINGLETON_ERROR, [aProvider.ClassName]));
    fSingletons.Add(aInterfaceGuid, nil);
  end;

  fProviders.Add(aInterfaceGuid, lType);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddServices(aServices: array of TClass);
const
  REG_ERROR          = 'Service has already been registered: %s';
  SINGLETON_ERROR    = 'A singleton exists for this service, unable to register: %s';
  ATTR_ERROR         = '%s is missing [TRegister] attribute for registration.';
  MISSING_IFCE_ERROR = 'cannot find an interface for: %s';
  IMPL_ERROR         = '%s does not implement interface %s';
var
  lType:       TRttiType;
  lInstance:   TRttiInstanceType;
  lGuid:       TGuid;
  lService:    TClass;
  lName:       string;
  lAttr:       TRegisterAttribute;
  lIsProvider: boolean;
begin
  for lService in aServices do
  begin
    lType     := fContext.GetType(lService);
    lAttr     := lType.GetAttribute<TRegisterAttribute>;
    lInstance := lType.AsInstance;
    lName     := lService.ClassName;

    if not Assigned(lAttr) then
    begin
      { we have don't have an attribute, let's search the cache for a provider for the first suitable interface }

      lGuid := Stream<TRttiInterfaceType>
        .From(lInstance.GetImplementedInterfaces)
        .Map<TGuid>(function(i: TRttiInterfaceType):TGuid begin Result := i.GUID; end)
        .First;

      lIsProvider := false;

      for lType in fCache do
      begin
        lInstance := lType.AsInstance;

        lIsProvider := Stream<TRttiInterfaceType>
          .From(lInstance.GetImplementedInterfaces)
          .AnyMatch(function(i: TRttiInterfaceType): boolean begin Result := i.GUID = lGUID; end);

         if lIsProvider then break;
      end;

      Expect.IsTrue(lIsProvider, Format(IMPL_ERROR, [lName, GUIDToString(lGuid)]));
    end
    else
    begin
      { otherwise, let's match the attribute }

      lGuid := lAttr.InterfaceGUID;

      Expect.IsFalse(fProviders.ContainsKey(lGuid), Format(REG_ERROR, [lName]));

      if lAttr.IsByForce then
      begin
        {----------------------------------------------------------------------------------------------------}
        { this block allows you to resolve against the interface map, rather than an inherited one. Delphi   }
        { has a lot of quirks, keeping this for an edge case. If you need to use, remember to add a dummy    }
        { private variable for the interface you want, or the linker may drop it:                            }
        {                                                                                                    }
        { [TRegister(IMoveCommandHandler, rtFromMap)]                    <-- resolve for IMoveCommandHandler }
        { TMoveCommandHandler = class(TTransient, ICommandIntentHandler) <-- but a base interface            }
        { private                                                                                            }
        {   fDummy: IMoveCommandHandler;                                 <-- prevent linker dropping ifce    }
        {                                                                                                    }
        { this allows us to resolve for IMoveCommandHandler but cast to the base ICommandIntentHandler       }
        { interface. Allowing us to add resolved interfaces to a list of ICommandIntentHandlers.             }
        { it's a pretty ugly hack, so as a rule ignore it. But it works if you are stuck.                    }
        {                                                                                                    }
        { this block trusts the developer knows what he is doing.                                            }
        {----------------------------------------------------------------------------------------------------}
        Expect.IsTrue(fInterfaceMap.ContainsKey(lGuid), Format(MISSING_IFCE_ERROR, [lName]));
      end
      else
      begin
        {----------------------------------------------------------------------------------------------------}
        { this block is the ordinary path, and it will ensure the type implements the specified interface.   }
        {----------------------------------------------------------------------------------------------------}
        lIsProvider := Stream<TRttiInterfaceType>
          .From(lInstance.GetImplementedInterfaces)
          .AnyMatch(function(i: TRttiInterfaceType): boolean begin Result := i.GUID = lAttr.InterfaceGUID; end);

        Expect.IsTrue(lIsProvider, Format(IMPL_ERROR, [lName, GUIDToString(lGuid)]));
      end;
    end;

    if lService.InheritsFrom(TSingleton) then
    begin
      Expect.IsFalse(fSingletons.ContainsKey(lGUID), Format(SINGLETON_ERROR, [lName]));
      fSingletons.Add(lGUID, nil);
    end;

    fProviders.Add(lGUID, lType);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddSingleton<TService, TProvider>(aInstance: TProvider);
const
  ALREADY_REGISTERED = 'singleton has already been registered';
var
  lGuid: TGuid;
begin
  lGuid := RegisterType<TService, TProvider>;

  Expect.IsFalse(fSingletons.ContainsKey(lGuid), ALREADY_REGISTERED);

  fSingletons.Add(lGuid, aInstance);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.Get<TService>(aClass: TClass): TService;
var
  lType:  TRttiType;
  lValue: TValue;
begin
  lType  := fContext.GetType(aClass);
  lValue := Resolve(lType);
  Result := lValue.AsType<TService>;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.Get<TService>(aGuid: TGuid): TService;
const
  IFCE_NOT_FOUND = 'interface not found: %s';
var
  lType: TRttiType;
  lValue: TValue;
begin
  Expect.IsTrue(fInterfaceMap.ContainsKey(aGuid), Format(IFCE_NOT_FOUND, [GUIDToString(aGuid)]));

  lType  := fInterfaceMap[aGuid];
  lValue := Resolve(lType);
  Result := lValue.AsType<TService>;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.Get<TService>: TService;
var
  lType:    TRttiType;
  lValue:   TValue;
begin
  lType  := fContext.GetType(TypeInfo(TService));
  lValue := Resolve(lType);
  Result := lValue.AsType<TService>;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.Resolve(const [ref] aType: TRttiType): TValue;
const
  PROVIDER_ERROR = 'Unable to find a provider for: ';
var
  lType: TRttiType;
  lName: string;
  lValue: TValue;
  lRttiClass: TRttiInstanceType;
  lInstance: TRttiInstanceType;
  lGuid: TGuid;
  lIsProvider: boolean;
  lMethod: TRttiMethod;
  lConstructor: TRttiMethod;
  lCount: integer;
  lParameters: TArray<TRttiParameter>;
  lValues: TArray<TValue>;
begin
  lType := aType;
  
  if lType.TypeKind <> tkClass then
  begin  
    lName := lType.QualifiedName;
    lGuid := GetTypeData(lType.Handle)^.Guid;

    if (fSingletons.ContainsKey(lGuid)) and (Assigned(fSingletons[lGuid])) then
      exit(fSingletons[lGuid]);

    lIsProvider := fProviders.ContainsKey(lGuid);

    if lIsProvider then
      lType := fProviders[lGuid]
    else
    begin
      for lType in fCache do
      begin
        if not (lType is TRttiInstanceType) then continue;

        lRttiClass := lType as TRttiInstanceType;

        lIsProvider := Stream<TRttiInterfaceType>
          .From(lRttiClass.GetImplementedInterfaces)
          .AnyMatch(function(i: TRttiInterfaceType): boolean begin Result := i.GUID = lGuid; end);

        if lIsProvider then
        begin
          fProviders.Add(lGuid, lType);
          break;
        end;
      end;

      Expect.IsTrue(lIsProvider, PROVIDER_ERROR + lName);
    end;
  end;

  lInstance := lType.AsInstance;

  if not (lType is TRttiInstanceType) then
   lConstructor := lInstance.GetMethod('Create')
  else
  begin
    lConstructor := Stream<TRttiMethod>
       .From(lInstance.GetDeclaredMethods)
       .Filter(function(m: TRttiMethod): boolean
          begin
            Result := (m.IsConstructor) and (m.Visibility = mvPublic) and (m.Parent = lType);
          end)
        .Filter(function(m: TRttiMethod): boolean
          begin
            Result := AllParamsAreInterfaces(m)
          end)
        .FirstOr(lInstance.GetMethod('Create'));
  end;

  lParameters := lConstructor.GetParameters;

  if Length(lParameters) = 0 then
    lValues := []
  else
  begin
    lValues := Stream<TRttiParameter>.From(lConstructor.GetParameters)
      .Map<TValue>(function(p: TRttiParameter): TValue
        begin
          Result := Resolve(p.ParamType)
        end)
      .ToArray;
  end;

  lValue := lConstructor.Invoke(lInstance.MetaclassType, lValues);

  if lInstance.MetaclassType.InheritsFrom(TSingleton) then
    fSingletons.AddOrSetValue(lGuid, lValue.AsObject);

  Result := lValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.AllParamsAreInterfaces(const [ref] aMethod: TRttiMethod): boolean;
var
  lParam: TRttiParameter;
  lParams: TArray<TRttiParameter>;
begin
  lParams := aMethod.GetParameters;

  if Length(lParams) = 0 then exit(false);

  for lParam in lParams do
  begin
    if not Assigned(lParam.ParamType) then exit(false);
    if lParam.ParamType.TypeKind <> tkInterface then exit(false);
  end;

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.ClassImplements<TService>(AClass: TClass): Boolean;
var
  lType: TRTTIType;
  lRttiClass: TRttiInstanceType;
  lGuid: TGuid;
begin
  lType      := fContext.GetType(TypeInfo(TService));
  lGuid      := GetTypeData(lType.Handle)^.Guid;
  lRttiClass := fContext.GetType(AClass) as TRttiInstanceType;

  Result := Stream<TRttiInterfaceType>
    .From(lRttiClass.GetImplementedInterfaces)
    .AnyMatch(function(i: TRttiInterfaceType): boolean begin Result := i.GUID = lGuid; end);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TContainer.Create;
begin
  fCache        := TList<TRttiType>.Create;
  fInterfaceMap := TDictionary<TGUID, TRttiType>.Create;
  fProviders    := TDictionary<TGuid, TRttiType>.Create;
  fSingletons   := TObjectDictionary<TGuid, TObject>.Create([doOwnsValues]);

  Initialize;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TContainer.Destroy;
begin
  fCache.Free;
  fInterfaceMap.Free;
  fProviders.Free;
  fSingletons.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TSingleContainer.Create;
begin
  fInstance := TContainer.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TSingleContainer.Destroy;
begin
  FreeAndNil(fInstance);
end;

end.
