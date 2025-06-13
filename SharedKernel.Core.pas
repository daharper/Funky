unit SharedKernel.Core;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Variants,
  System.Generics.Defaults,
  System.Generics.Collections,
  System.Messaging;

type
  { type aliases to reduce bloat }
  TStrList   = TList<string>;

  { predicate with a var argument }
  TProcvar<T> = reference to procedure (var Arg1: T);

  { semantic abstractions for interface management }
  TSingleton = class(TNoRefCountObject);
  TTransient = class(TInterfacedObject);

  { determines whether the container will use the type or interface map to resolve the provide }
  TRegisterType = (rtFromType, rtFromMap);

  { supplies interface to provider mapping, or facilitates flexible registration }
  TRegisterAttribute = class(TCustomAttribute)
  private
    fInterfaceGUID: TGUID;
    fRegisterType: TRegisterType;
  public
    property InterfaceGUID: TGUID read fInterfaceGUID;
    property RegisterType: TRegisterType read fRegisterType;

    function IsByForce: boolean;

    constructor Create(const aInterfaceGUID: TGUID; aRegisterType: TRegisterType = rtFromType);
  end;

  { basic guard class }
  TExpect = class
  private
    class var
      fInstance: TExpect;
  public
    function IsNotBlank(const aValue: string; const aMessage: string = ''): TExpect;
    function IsEmpty<T>(const aList: TList<T>; const aMessage: string = ''): TExpect;
    function IsAssigned<T>(aInstance: T; const aMessage: string = ''): TExpect;
    function IsTrue(aValue: boolean; const aMessage: string = ''): TExpect;
    function IsFalse(aValue: boolean; const aMessage: string = ''): TExpect;

    class constructor Create;
    class destructor Destroy;
  end;

  { guard class exception }
  TExpectException = class(Exception)
  public
    class procedure Throw(const aMessage: string; const aDefaultMessage: string = '');
  end;

  { language extensions, for global functions that require generics }
  TLx = class
  public
    class procedure Swap<T>(var lhs: T; var rhs:T);
    class function Iff<T>(aCondition: boolean; aTrueValue: T; aFalseValue: T): T;
  end;

  { used for managing local references, avoids try/finally/free blocks }
  TScope = record
  private
    fInstances: TObjectList<TObject>;
  public
    function Add<T:class>(aInstance: T): T; overload;
    function Add<T:class, constructor>: T; overload;

    class operator Initialize (out Dest: TScope);
    class operator Finalize (var Dest: TScope);
  end;

  { interface for a readonly list }
  IReadOnlyList<T> = interface
    ['{2E67E9AB-AE1F-4A89-96F3-B1B7C0AD8F85}']
    function Count: Integer;
    function HasData: boolean;
    function IsEmpty: boolean;
    function GetItem(Index: Integer): T;
    function GetEnumerator: TEnumerator<T>;
    property Items[Index: Integer]: T read GetItem; default;
  end;

  { simple readonly list - note: we don't own the items we just wrap }
  TReadOnlyList<T> = class(TInterfacedObject, IReadOnlyList<T>)
  private
    fItems: TList<T>;
    fFreeRequired: Boolean;
  public
    function Count: Integer;
    function HasData: boolean;
    function IsEmpty: boolean;
    function GetItem(Index: Integer): T;
    function GetEnumerator: TEnumerator<T>;

    property Item[aIndex: integer]: T read GetItem; default;

    constructor Create(const aList: TList<T>);
    destructor Destroy; override;

    class function From(const aList: TList<T>): IReadOnlyList<T>;
  end;

  /// <summary>Represents an optional value. Inspired by Option/Maybe monads.</summary>
  /// <typeparam name="T">Type of the optional value</typeparam>
  TMaybe<T> = record
  private
    FHasValue: Boolean;
    FValue: T;

    /// <summary>Accesses the value. Raises if value is not present.</summary>
    /// <summary>Returns the value if successful. Raises on error.</summary>
    function GetValue: T;

  public
    /// <summary>The value if successful.</summary>
    property Value: T read GetValue;

    /// <summary>Returns true if value is present.</summary>
    function IsSome: Boolean;

    /// <summary>Returns true if no value is present.</summary>
    function IsNone: Boolean;

    /// <summary>Returns the value if present, otherwise the fallback.</summary>
    function OrElse(const Fallback: T): T;

    /// <summary>Returns the value if present, otherwise computes it from the function.</summary>
    function OrElseGet(Func: TFunc<T>): T;

    /// <summary>Constructs a TMaybe with a value.</summary>
    class function Some(const AValue: T): TMaybe<T>; static;

    /// <summary>Constructs an empty TMaybe.</summary>
    class function None: TMaybe<T>; static;
  end;

  /// <summary>Represents the result of an operation: either a value or an error.</summary>
  /// <typeparam name="T">Type of the value on success</typeparam>
  TResult<T> = record
  private
    FValue: T;
    FError: string;
    FOk: Boolean;

    function GetValue: T;

    /// <summary>Returns the error message if failed.</summary>
    function GetError: string;

  public
     /// <summary>Constructs a successful result.</summary>
    class function Ok(const AValue: T): TResult<T>; static;

    /// <summary>Constructs an error result.</summary>
    class function Err(const AError: string): TResult<T>; static;

    /// <summary>True if result is success.</summary>
    function IsOk: Boolean;

    /// <summary>True if result is error.</summary>
    function IsErr: Boolean;

    property Value: T read GetValue;
        /// <summary>The error message if failed.</summary>
    property Error: string read GetError;
  end;

  TResultWrapper<T> = record
  private
    FRes: TResult<T>;

    /// Returns the underlying TResult<T> value
    function GetResult: TResult<T>;

  public
    /// Exposes the wrapped TResult<T>
    property Result: TResult<T> read GetResult;

    /// Creates a new wrapper around a TResult<T>
    constructor Create(const ARes: TResult<T>);

    /// Maps a successful value to another type
    /// <summary>Applies a mapping function to the successful result value.</summary>
    /// <param name="Func">Mapping function from T to U</param>
    /// <returns>A new TResultWrapper<U></returns>
    /// <example>
    ///   Result.Wrap(5).Map(function(i) begin Result := i * 2; end);
    /// </example>
    function Map<U>(Func: TFunc<T, U>): TResultWrapper<U>;

    /// Binds a function that returns TResult<U> to a successful value
    /// <summary>Chains a result-producing function to the successful value.</summary>
    /// <param name="Func">Function returning TResult<U></param>
    /// <returns>A new TResultWrapper<U></returns>
    /// <example>
    ///   Result.Wrap(5).Bind(function(i) begin Result := TResult<Integer>.Ok(i * 2); end);
    /// </example>
    function Bind<U>(Func: TFunc<T, TResult<U>>): TResultWrapper<U>;

    /// Applies a wrapped function to the current value
    /// <summary>Applies a wrapped function to the successful value.</summary>
    /// <param name="FuncRes">A TResult containing a function to apply</param>
    /// <returns>A new TResultWrapper<U></returns>
    /// <example>
    ///   Result.Wrap(5).Apply(Result.Wrap(function(i): string begin Result := IntToStr(i); end));
    /// </example>
    function Apply<U>(FuncRes: TResult<TFunc<T, U>>): TResultWrapper<U>;

    /// Recovers from an error by returning an alternate result
    function Recover(Func: TFunc<string, TResult<T>>): TResultWrapper<T>;

    /// Maps the error message to a different one
    function MapError(Func: TFunc<string, string>): TResultWrapper<T>;

    /// Uses a fallback TResult<T> if the current one is an error
    function OrElse(const Fallback: TResult<T>): TResultWrapper<T>;

    /// Combines this result with another using a combining function
    /// <summary>Combines two results using a mapping function if both are successful.</summary>
    /// <param name="Other">The second result to combine with</param>
    /// <param name="Func">A function combining both values</param>
    /// <returns>A TResultWrapper<R> of the combined value</returns>
    /// <example>
    ///   Result.Wrap(2).Zip(Result.Wrap(3), function(a, b): string begin Result := IntToStr(a + b); end);
    /// </example>
    function Zip<U, R>(const Other: TResult<U>; const Func: TFunc<T, U, R>): TResultWrapper<R>;

    /// LINQ-style flatMap with a projector function
    /// <summary>Performs a flatMap operation with projection, similar to LINQ's SelectMany.</summary>
    /// <param name="Binder">Function producing inner TResult<U></param>
    /// <param name="Projector">Combines outer and inner values into final result</param>
    /// <returns>A new TResultWrapper<R></returns>
    /// <example>
    ///   Result.Wrap(5).SelectMany(
    ///     function(i): TResult<string> begin Result := TResult<string>.Ok(IntToStr(i)); end,
    ///     function(i, s): string begin Result := Format('%d as %s', [i, s]); end);
    /// </example>
    function SelectMany<U, R>(const Binder: TFunc<T, TResult<U>>; const Projector: TFunc<T, U, R>): TResultWrapper<R>;

    /// Validates the result with a predicate, returns error if false
    function Ensure(Predicate: TPredicate<T>; const ErrorMsg: string): TResultWrapper<T>;

    /// Executes an action if result is successful
    function Tap(Action: TProc<T>): TResultWrapper<T>;

    /// Executes an action if result is an error
    function TapError(Action: TProc<string>): TResultWrapper<T>;

    /// Alias for Tap - runs on success
    function OnSuccess(Action: TProc<T>): TResultWrapper<T>;

    /// Alias for TapError - runs on failure
    function OnFail(Action: TProc<string>): TResultWrapper<T>;

    /// Ensures a class-type value is not nil
    function EnsureNotNull(const Msg: string): TResultWrapper<T>;

    /// Enforces a predicate, returns error if false
    function Expect(Predicate: TPredicate<T>; const Msg: string): TResultWrapper<T>;

    /// Outputs result to debugger log
    function Log(const Tag: string = ''): TResultWrapper<T>;

    /// Conditionally transforms the result based on predicate
    function IfThen(Predicate: TPredicate<T>; Func: TFunc<T, TResult<T>>): TResultWrapper<T>;

    /// Conditionally recovers from error based on predicate
    function IfErrThen(Predicate: TPredicate<string>; Func: TFunc<string, TResult<T>>): TResultWrapper<T>;

    /// Maps result based on predicate, with optional fallback
    function IfThenMap<U>(Predicate: TPredicate<T>; Func: TFunc<T, U>; ElseFunc: TFunc<T, U> = nil): TResultWrapper<U>;

    /// Executes action based on predicate, optionally when false
    function IfThenTap(Predicate: TPredicate<T>; Action: TProc<T>; ElseAction: TProc<T> = nil): TResultWrapper<T>;

    /// Maps error based on predicate, with optional fallback
    function IfErrThenMap(Predicate: TPredicate<string>; Func: TFunc<string, T>; ElseFunc: TFunc<string, T> = nil): TResultWrapper<T>;

    /// Executes action on error based on predicate
    function IfErrThenTap(Predicate: TPredicate<string>; Action: TProc<string>; ElseAction: TProc<string> = nil): TResultWrapper<T>;

    /// Runs action if error message matches predicate
    function OnErrorMatch(Predicate: TPredicate<string>; Action: TProc<string>): TResultWrapper<T>;

    /// Transforms error message based on predicate
    function OnErrorMap(Predicate: TPredicate<string>; Recovery: TFunc<string, T>): TResultWrapper<T>;

    /// Executes action if result value matches predicate
    function OnMatch(Predicate: TPredicate<T>; Action: TProc<T>): TResultWrapper<T>;

    /// Transforms result based on value matching predicate
    function OnMatchMap<U>(Predicate: TPredicate<T>; Mapper: TFunc<T, U>; ElseMapper: TFunc<T, U> = nil): TResultWrapper<U>;

    /// Pattern-matching like behavior with side effects
    procedure Match(OnOk: TProc<T>; OnErr: TProc<string>);
  end;

  TResult = record
    /// Wraps a TResult<T> in a fluent wrapper
    class function Wrap<T>(const Res: TResult<T>): TResultWrapper<T>; static;

    /// Wraps a value in a fluent wrapper
    class function WrapValue<T>(const Value: T): TResultWrapper<T>; static;

    /// Wraps an error in a fluent wrapper
    class function WrapError<T>(const Msg: string): TResultWrapper<T>; static;

    /// Creates a TResult<T> from a function, catching exceptions
    class function From<T>(Func: TFunc<T>): TResult<T>; static;
  end;

  TResultOps = class
  private
    class var fInstance: TResultOps;
  public
    class constructor Create;
    class destructor Destroy;

    /// Singleton instance for operations
    class property Instance: TResultOps read fInstance;

    function Map<T, U>(const Res: TResult<T>; const Func: TFunc<T, U>): TResult<U>;
    function Bind<T, U>(const Res: TResult<T>; const Func: TFunc<T, TResult<U>>): TResult<U>;
    function Apply<T, U>(const Res: TResult<T>; const FuncRes: TResult<TFunc<T, U>>): TResult<U>;
    function Zip<T1, T2, R>(const A: TResult<T1>; const B: TResult<T2>; const Func: TFunc<T1, T2, R>): TResult<R>;
    function SelectMany<T, U, R>(const Res: TResult<T>; const Binder: TFunc<T, TResult<U>>; const Projector: TFunc<T, U, R>): TResult<R>;
    function OrElse<T>(const Res: TResult<T>; const Fallback: TResult<T>): TResult<T>;
    function MapError<T>(const Res: TResult<T>; const Func: TFunc<string, string>): TResult<T>;
    function Recover<T>(const Res: TResult<T>; const Handler: TFunc<string, TResult<T>>): TResult<T>;
    function Ensure<T>(const Res: TResult<T>; const Predicate: TPredicate<T>; const ErrorMsg: string): TResult<T>;
    function Tap<T>(const Res: TResult<T>; const Action: TProc<T>): TResult<T>;
    function TapError<T>(const Res: TResult<T>; const Action: TProc<string>): TResult<T>;
    procedure Match<T>(const Res: TResult<T>; OnOk: TProc<T>; OnErr: TProc<string>);
  end;

  TLazy<T> = record
  private
    FFunc: TFunc<T>;
    FValue: T;
    FHasValue: Boolean;
    function GetValue: T;
  public
    /// Returns the evaluated value, executing the function once
    property Value: T read GetValue;

    /// Tries to get the value without evaluating if not already
    function TryValue(out V: T): Boolean;

    /// Checks whether the value has already been computed
    function IsEvaluated: Boolean;

    /// Resets the cached state, making it lazy again
    procedure Reset;

    /// Creates a lazy wrapper around a function
    class function Create(Func: TFunc<T>): TLazy<T>; static;

    /// Converts a TResult into a lazy evaluation
    class function FromResult(const Res: TResult<T>): TLazy<T>; static;
  end;

  TUse<T: class> = class
  public
    /// Executes a function with a resource, and optionally disposes it
    class function Exec<U>(Instance: T; func: TFunc<T, TResult<U>>; cleanup: TProc<T> = nil): TResultWrapper<U>; overload; static;

    /// Executes a function returning a Maybe<T>, with optional cleanup
    class function Exec<U>(Instance: T; func: TFunc<T, TMaybe<U>>; cleanup: TProc<T> = nil): TMaybe<U>; overload; static;
  end;

  { Functions }

  function Iff(aCondition: boolean; const aTrueValue: string; const aFalseValue: string): string; overload;
  function Iff(aCondition: boolean; aTrueValue: integer; aFalseValue: integer): integer; overload;
  function Iff(aCondition: boolean; const aTrueValue: char; const aFalseValue: char): char; overload;
  function ToPair(const aString: string; const aDelimiter: string): TPair<string, string>;
  function Expect: TExpect;

implementation

uses
  System.StrUtils,
  System.TypInfo,
  System.Character;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function Expect: TExpect;
begin
  Result := TExpect.fInstance;
end;

{----------------------------------------------------------------------------------------------------------------------}
function ToPair(const aString: string; const aDelimiter: string): TPair<string, string>;
var
  lParts: TArray<string>;
begin
  lParts := SplitString(aString, aDelimiter);
  Result := TPair<string, string>.Create(lParts[0], lParts[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function IsEmpty(aString: string): boolean;
begin
  Result := Length(aString) = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function IsBlank(aString: string): boolean;
begin
  Result := (Length(aString) = 0) or (Length(Trim(aString)) = 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Iff(aCondition: boolean; const aTrueValue: char; const aFalseValue: char): char;
begin
  if aCondition then
    Result := aTrueValue
  else
    Result := aFalseValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Iff(aCondition: boolean; const aTrueValue: string; const aFalseValue: string): string;
begin
  if aCondition then
    Result := aTrueValue
  else
    Result := aFalseValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Iff(aCondition: boolean; aTrueValue: integer; aFalseValue: integer): integer;
begin
  if aCondition then
    Result := aTrueValue
  else
    Result := aFalseValue;
end;

{ TLx }

{----------------------------------------------------------------------------------------------------------------------}
class function TLx.Iff<T>(aCondition: boolean; aTrueValue, aFalseValue: T): T;
begin
  if aCondition then
    Result := aTrueValue
  else
    Result := aFalseValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Swap<T>(var lhs: T; var rhs: T);
var
  lTemp: T;
begin
  lTemp := lhs;
  lhs   := rhs;
  rhs   := lTemp;
end;

{ TRegisterAttribute }

{----------------------------------------------------------------------------------------------------------------------}
constructor TRegisterAttribute.Create(const aInterfaceGUID: TGUID; aRegisterType: TRegisterType);
begin
  inherited Create;

  fInterfaceGUID := aInterfaceGUID;
  fRegisterType  := aRegisterType;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRegisterAttribute.IsByForce: boolean;
begin
  Result := fRegisterType = rtFromMap;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExpect.IsNotBlank(const aValue, aMessage: string): TExpect;
const
  BLANK_ERROR = 'value is blank error';
begin
  if string.IsNullOrWhiteSpace(aValue) then
    TExpectException.Throw(aMessage, BLANK_ERROR);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExpect.IsTrue(aValue: boolean; const aMessage: string): TExpect;
const
  CONDITION_ERROR = 'condition is false error';
begin
  if not aValue then
    TExpectException.Throw(aMessage, CONDITION_ERROR);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExpect.IsFalse(aValue: boolean; const aMessage: string): TExpect;
const
  CONDITION_ERROR = 'condition is true error';
begin
  if aValue then
    TExpectException.Throw(aMessage, CONDITION_ERROR);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExpect.IsAssigned<T>(aInstance: T; const aMessage: string): TExpect;
const
  NOT_ASSIGNED_ERROR = 'this instance is not assigned error';
begin
  if aInstance = default(T) then
    TExpectException.Throw(aMessage, NOT_ASSIGNED_ERROR);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExpect.IsEmpty<T>(const aList: TList<T>; const aMessage: string): TExpect;
const
  NOT_EMPTY_ERROR = 'the list is not empty error';
begin
  if aList.Count > 0 then
    TExpectException.Throw(aMessage, NOT_EMPTY_ERROR);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TExpect.Create;
begin
  fInstance := TExpect.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TExpect.Destroy;
begin
  FreeAndNil(fInstance);
end;

{ TExpectException }

{----------------------------------------------------------------------------------------------------------------------}
class procedure TExpectException.Throw(const aMessage, aDefaultMessage: string);
var
  lMessage: string;
begin
  if Length(aMessage) > 0 then
    lMessage := aMessage
  else
    lMessage := aDefaultMessage;

  raise TExpectException.Create(lMessage);
end;


{ TScope }

{----------------------------------------------------------------------------------------------------------------------}
class operator TScope.Initialize(out Dest: TScope);
begin
  Dest.fInstances := TObjectList<TObject>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TScope.Add<T>(aInstance: T): T;
begin
  fInstances.Add(aInstance);
  Result := aInstance;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TScope.Add<T>: T;
begin
  Result := T.Create;
  fInstances.Add(Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TScope.Finalize(var Dest: TScope);
begin
  Dest.fInstances.Free;
end;

{ TMaybe<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function TMaybe<T>.Some(const AValue: T): TMaybe<T>;
begin
  Result.FHasValue := True;
  Result.FValue := AValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TMaybe<T>.None: TMaybe<T>;
begin
  Result.FHasValue := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMaybe<T>.OrElse(const Fallback: T): T;
begin
  if FHasValue then
    Result := FValue
  else
    Result := Fallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsSome: Boolean;
begin
  Result := FHasValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsNone: Boolean;
begin
  Result := not FHasValue;
end;

function TMaybe<T>.GetValue: T;
begin
  if not FHasValue then
    raise Exception.Create('Cannot access value of None');

  Result := FValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMaybe<T>.OrElseGet(Func: TFunc<T>): T;
begin
  if FHasValue then
    Result := FValue
  else
    Result := Func();
end;

{ TResult<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Ok(const AValue: T): TResult<T>;
begin
  Result.FValue := AValue;
  Result.FError := '';
  Result.FOk := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Err(const AError: string): TResult<T>;
begin
  Result.FOk := False;
  Result.FError := AError;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.IsOk: Boolean;
begin
  Result := FOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.IsErr: Boolean;
begin
  Result := not FOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.GetValue: T;
begin
  if not FOk then
    raise Exception.Create('Cannot access Value of Err result');

  Result := FValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.GetError: string;
begin
  Result := FError;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult.From<T>(Func: TFunc<T>): TResult<T>;
begin
  try
    Result := TResult<T>.Ok(Func());
  except
    on E: Exception do
      Result := TResult<T>.Err(E.Message);
  end;
end;

{ TResultWrapper<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TResultWrapper<T>.Create(const ARes: TResult<T>);
begin
  FRes := ARes;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Map<U>(Func: TFunc<T, U>): TResultWrapper<U>;
begin
  Result := TResultWrapper<U>.Create(TResultOps.Instance.Map<T, U>(FRes, Func));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Recover(Func: TFunc<string, TResult<T>>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.Recover<T>(FRes, Func));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Bind<U>(Func: TFunc<T, TResult<U>>): TResultWrapper<U>;
begin
  Result := TResultWrapper<U>.Create(TResultOps.Instance.Bind<T, U>(FRes, Func));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Apply<U>(FuncRes: TResult<TFunc<T, U>>): TResultWrapper<U>;
begin
  Result := TResultWrapper<U>.Create(TResultOps.Instance.Apply<T, U>(FRes, FuncRes));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.GetResult: TResult<T>;
begin
  Result := FRes;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfThen(Predicate: TPredicate<T>; Func: TFunc<T, TResult<T>>): TResultWrapper<T>;
begin
  if FRes.IsOk and Predicate(FRes.Value) then
    Exit(TResultWrapper<T>.Create(Func(FRes.Value)));

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfThenMap<U>(Predicate: TPredicate<T>; Func: TFunc<T, U>; ElseFunc: TFunc<T, U> = nil): TResultWrapper<U>;
begin
  if not FRes.IsOk then
    Exit(TResultWrapper<U>.Create(TResult<U>.Err(FRes.Error)));

  if not Predicate(FRes.Value) then
  begin
    if Assigned(ElseFunc) then
      Exit(TResultWrapper<U>.Create(TResult<U>.Ok(ElseFunc(FRes.Value))));

    Exit(TResultWrapper<U>.Create(TResult<U>.Err('IfThenMap: condition not met')));
  end;

  Result := TResultWrapper<U>.Create(TResult<U>.Ok(Func(FRes.Value)));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfThenTap(Predicate: TPredicate<T>; Action: TProc<T>; ElseAction: TProc<T> = nil): TResultWrapper<T>;
begin
  if FRes.IsOk then
  begin
    if Predicate(FRes.Value) then
      Action(FRes.Value)
    else if Assigned(ElseAction) then
      ElseAction(FRes.Value);
  end;

  Result := Self;
end;
{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfErrThen(Predicate: TPredicate<string>; Func: TFunc<string, TResult<T>>): TResultWrapper<T>;
begin
  if FRes.IsErr and Predicate(FRes.Error) then
    Exit(TResultWrapper<T>.Create(Func(FRes.Error)));

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfErrThenMap(Predicate: TPredicate<string>; Func, ElseFunc: TFunc<string, T>): TResultWrapper<T>;
begin
  if FRes.IsOk then
    Exit(Self);

  if not Predicate(FRes.Error) then
  begin
    if Assigned(ElseFunc) then
      Exit(TResultWrapper<T>.Create(TResult<T>.Ok(ElseFunc(FRes.Error))))
    else
      Exit(Self);
  end;

  Result := TResultWrapper<T>.Create(TResult<T>.Ok(Func(FRes.Error)));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.IfErrThenTap(Predicate: TPredicate<string>; Action, ElseAction: TProc<string>): TResultWrapper<T>;
begin
  if FRes.IsErr then
  begin
    if Predicate(FRes.Error) then
      Action(FRes.Error)
    else if Assigned(ElseAction) then
      ElseAction(FRes.Error);
  end;

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.MapError(Func: TFunc<string, string>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.MapError<T>(FRes, Func));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OrElse(const Fallback: TResult<T>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.OrElse<T>(FRes, Fallback));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Zip<U, R>(const Other: TResult<U>; const Func: TFunc<T, U, R>): TResultWrapper<R>;
begin
  Result := TResultWrapper<R>.Create(TResultOps.Instance.Zip<T, U, R>(FRes, Other, Func));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.SelectMany<U, R>(const Binder: TFunc<T, TResult<U>>; const Projector: TFunc<T, U, R>): TResultWrapper<R>;
begin
  Result := TResultWrapper<R>.Create(TResultOps.Instance.SelectMany<T, U, R>(FRes, Binder, Projector));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Ensure(Predicate: TPredicate<T>; const ErrorMsg: string): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.Ensure<T>(FRes, Predicate, ErrorMsg));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Tap(Action: TProc<T>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.Tap<T>(FRes, Action));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.TapError(Action: TProc<string>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(TResultOps.Instance.TapError<T>(FRes, Action));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnSuccess(Action: TProc<T>): TResultWrapper<T>;
begin
  Result := Tap(Action);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnErrorMap(Predicate: TPredicate<string>; Recovery: TFunc<string, T>): TResultWrapper<T>;
begin
  Result := IfErrThenMap(Predicate, Recovery);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnErrorMatch(Predicate: TPredicate<string>; Action: TProc<string>): TResultWrapper<T>;
begin
  Result := IfErrThenTap(Predicate, Action);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnFail(Action: TProc<string>): TResultWrapper<T>;
begin
  Result := TapError(Action);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnMatch(Predicate: TPredicate<T>; Action: TProc<T>): TResultWrapper<T>;
begin
  if FRes.IsOk and Predicate(FRes.Value) then
    Action(FRes.Value);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.OnMatchMap<U>(Predicate: TPredicate<T>; Mapper, ElseMapper: TFunc<T, U>): TResultWrapper<U>;
begin
  if not FRes.IsOk then
    Exit(TResultWrapper<U>.Create(TResult<U>.Err(FRes.Error)));

  if Predicate(FRes.Value) then
    Exit(TResultWrapper<U>.Create(TResult<U>.Ok(Mapper(FRes.Value))))
  else if Assigned(ElseMapper) then
    Exit(TResultWrapper<U>.Create(TResult<U>.Ok(ElseMapper(FRes.Value))))
  else
    Exit(TResultWrapper<U>.Create(TResult<U>.Err('OnMatchMap: predicate not met')));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.EnsureNotNull(const Msg: string): TResultWrapper<T>;
begin
 Result := Ensure(
    function(val: T): Boolean
    var
      Obj: TObject;
    begin
      if PTypeInfo(TypeInfo(T))^.Kind = tkClass then
        Obj := TObject(Pointer(@val)^)
      else
        Obj := nil;

      Result := Assigned(Obj);
    end, Msg);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Expect(Predicate: TPredicate<T>; const Msg: string): TResultWrapper<T>;
begin
  Result := Ensure(Predicate, Msg);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultWrapper<T>.Log(const Tag: string): TResultWrapper<T>;
begin
  Match(
    procedure(val: T)
    begin
     // OutputDebugString(PChar(Format('[OK] %s: %s', [Tag, TValue.From<T>(val).ToString])));
    end,
    procedure(err: string)
    begin
     // OutputDebugString(PChar(Format('[ERR] %s: %s', [Tag, err])));
    end);
  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultWrapper<T>.Match(OnOk: TProc<T>; OnErr: TProc<string>);
begin
  TResultOps.Instance.Match<T>(FRes, OnOk, OnErr);
end;

{ TResultFluent }

{----------------------------------------------------------------------------------------------------------------------}
class function TResult.Wrap<T>(const Res: TResult<T>): TResultWrapper<T>;
begin
  Result := TResultWrapper<T>.Create(Res);
end;

class function TResult.WrapValue<T>(const Value: T): TResultWrapper<T>;
begin
  Result := Wrap<T>(TResult<T>.Ok(Value));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult.WrapError<T>(const Msg: string): TResultWrapper<T>;
begin
  Result := Wrap<T>(TResult<T>.Err(Msg));
end;

{ TResultOps }

{----------------------------------------------------------------------------------------------------------------------}
class constructor TResultOps.Create;
begin
  fInstance := TResultOps.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TResultOps.Destroy;
begin
  fInstance.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Map<T, U>(const Res: TResult<T>; const Func: TFunc<T, U>): TResult<U>;
begin
  if Res.IsOk then
    Result := TResult<U>.Ok(Func(Res.Value))
  else
    Result := TResult<U>.Err(Res.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Bind<T, U>(const Res: TResult<T>; const Func: TFunc<T, TResult<U>>): TResult<U>;
begin
  if Res.IsOk then
    Result := Func(Res.Value)
  else
    Result := TResult<U>.Err(Res.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Apply<T, U>(const Res: TResult<T>; const FuncRes: TResult<TFunc<T, U>>): TResult<U>;
begin
  if not FuncRes.IsOk then
    Exit(TResult<U>.Err(FuncRes.Error));
  if not Res.IsOk then
    Exit(TResult<U>.Err(Res.Error));
  Result := TResult<U>.Ok(FuncRes.Value(Res.Value));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Zip<T1, T2, R>(const A: TResult<T1>; const B: TResult<T2>; const Func: TFunc<T1, T2, R>): TResult<R>;
begin
  if not A.IsOk then
    Exit(TResult<R>.Err(A.Error));
  if not B.IsOk then
    Exit(TResult<R>.Err(B.Error));
  Result := TResult<R>.Ok(Func(A.Value, B.Value));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.SelectMany<T, U, R>(const Res: TResult<T>; const Binder: TFunc<T, TResult<U>>; const Projector: TFunc<T, U, R>): TResult<R>;
var
  Intermediate: TResult<U>;
begin
  if Res.IsErr then
    Exit(TResult<R>.Err(Res.Error));

  Intermediate := Binder(Res.Value);

  if Intermediate.IsErr then
    Exit(TResult<R>.Err(Intermediate.Error));

  Result := TResult<R>.Ok(Projector(Res.Value, Intermediate.Value));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.OrElse<T>(const Res: TResult<T>; const Fallback: TResult<T>): TResult<T>;
begin
  if Res.IsOk then
    Result := Res
  else
    Result := Fallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Recover<T>(const Res: TResult<T>; const Handler: TFunc<string, TResult<T>>): TResult<T>;
begin
  if Res.IsOk then
    Result := Res
  else
    Result := Handler(Res.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.MapError<T>(const Res: TResult<T>; const Func: TFunc<string, string>): TResult<T>;
begin
  if Res.IsOk then
    Result := Res
  else
    Result := TResult<T>.Err(Func(Res.Error));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Ensure<T>(const Res: TResult<T>; const Predicate: TPredicate<T>; const ErrorMsg: string): TResult<T>;
begin
  if Res.IsOk and not Predicate(Res.Value) then
    Result := TResult<T>.Err(ErrorMsg)
  else
    Result := Res;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.Tap<T>(const Res: TResult<T>; const Action: TProc<T>): TResult<T>;
begin
  if Res.IsOk then
    Action(Res.Value);
  Result := Res;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResultOps.TapError<T>(const Res: TResult<T>; const Action: TProc<string>): TResult<T>;
begin
  if Res.IsErr then
    Action(Res.Error);
  Result := Res;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOps.Match<T>(const Res: TResult<T>; OnOk: TProc<T>; OnErr: TProc<string>);
begin
  if Res.IsOk then
    OnOk(Res.Value)
  else
    OnErr(Res.Error);
end;

{ TLazy<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function TLazy<T>.Create(Func: TFunc<T>): TLazy<T>;
begin
  Result.FFunc := Func;
  Result.FHasValue := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TLazy<T>.GetValue: T;
begin
  if not FHasValue then
  begin
    FValue := FFunc();
    FHasValue := True;
  end;
  Result := FValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TLazy<T>.IsEvaluated: Boolean;
begin
  Result := FHasValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLazy<T>.Reset;
begin
  FHasValue := False;
  FValue := Default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TLazy<T>.TryValue(out V: T): Boolean;
begin
  if FHasValue then
  begin
    V := FValue;
    Result := True;
  end
  else
    Result := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TLazy<T>.FromResult(const Res: TResult<T>): TLazy<T>;
begin
  Result := TLazy<T>.Create(
    function: T
    begin
      if Res.IsOk then
        Exit(Res.Value)
      else
        raise Exception.Create(Res.Error);
    end);
end;

{ TUse<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function TUse<T>.Exec<U>(instance: T; func: TFunc<T, TResult<U>>; cleanup: TProc<T>): TResultWrapper<U>;
begin
   try
    Result := TResultWrapper<U>.Create(Func(Instance));
  except
    on E: Exception do
      Result := TResultWrapper<U>.Create(TResult<U>.Err(E.Message));
  end;

  if Assigned(cleanup) then
    cleanup(instance)
  else
    instance.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TUse<T>.Exec<U>(instance: T; func: TFunc<T, TMaybe<U>>; cleanup: TProc<T>): TMaybe<U>;
begin
  try
    Result := Func(instance);
  except
    on E: Exception do
      Result := TMaybe<U>.None;
  end;

  if Assigned(cleanup) then
    cleanup(instance)
  else
    instance.Free;
end;

{ TReadonlyList<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TReadOnlyList<T>.Create(const aList: TList<T>);
begin
  inherited Create;

  if Assigned(aList) then
  begin
    fItems := aList;
    fFreeRequired := False;
  end
  else
  begin
    fItems := TList<T>.Create;
    fFreeRequired := True;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TReadOnlyList<T>.Destroy;
begin
  if fFreeRequired then
    fItems.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TReadOnlyList<T>.Count: Integer;
begin
  Result := fItems.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TReadOnlyList<T>.GetItem(Index: Integer): T;
begin
  Result := fItems[Index];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TReadOnlyList<T>.HasData: boolean;
begin
  Result := fItems.Count > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TReadOnlyList<T>.IsEmpty: boolean;
begin
  Result := fItems.Count = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TReadOnlyList<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := fItems.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReadOnlyList<T>.From(const aList: TList<T>): IReadOnlyList<T>;
begin
  Result := TReadOnlyList<T>.Create(aList);
end;

end.

