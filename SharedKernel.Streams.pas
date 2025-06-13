unit SharedKernel.Streams;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  SharedKernel.Core;

type
  Stream<T> = record
  private
    fList: TList<T>;

  public
    { terminating operations }
    function Count: integer;

    function AnyMatch(aPredicate: TPredicate<T>): boolean;

    function AllMatch(aPredicate: TPredicate<T>): boolean;

    function ToList: TList<T>;

    function ToArray: TArray<T>;

    function Reduce<U>(aValue: U; const reducer: TFunc<U,T,U>): U;

    function Min(aComparer: IComparer<T> = nil): T;

    function Max(aComparer: IComparer<T> = nil): T;

    function ToMap<K,V>(const aGen: TFunc<T,TPair<K,V>>): TDictionary<K, V>; overload;

    function ToMap<U>: TDictionary<T, U>; overload;

    function ToMap<U>(const aValueGen: TFunc<T, U>): TDictionary<T, U>; overload;

    function ToMap<U>(const aIdGen: TFunc<T, U>; aOwns: TDictionaryOwnerships = []): TObjectDictionary<U, T>; overload;

    function ToMap(const aIdGen: TFunc<T, string>; aIgnoreCase: boolean = true; aOwns: TDictionaryOwnerships = []): TObjectDictionary<string, T>; overload;

    function GroupBy(aComparer: IEqualityComparer<T> = nil): TDictionary<T, TList<T>>; overload;

    function GroupBy<U>(const aIdGen: TFunc<T,U>): TDictionary<U, TList<T>>; overload;

    function GroupBy(const aIdGen: TFunc<T,string>; aIgnoreCase: boolean = true): TDictionary<string, TList<T>>; overload;

    function First: T; overload;

    function First(aPredicate: TPredicate<T>):T; overload;

    function FirstOr(aDefault: T): T; overload;

    function FirstOrDefault:T; overload;

    function FirstOrDefault(aPredicate: TPredicate<T>):T; overload;

    function Last: T; overload;

    function Last(aPredicate: TPredicate<T>):T; overload;

    function LastOrDefault: T; overload;

    function LastOrDefault(aPredicate: TPredicate<T>):T; overload;

    procedure ForEach(aConsumer: TProc<T>);

    procedure Apply(aConsumer: TProcvar<T>);

    { transforming operations }

    function Filter(aPredicate: TPredicate<T>): Stream<T>;

    function Limit(aCount: integer): Stream<T>;

    function Map<U>(aMapper: TFunc<T, U>): Stream<U>;

    function Peek(aConsumer: TProc<T>): Stream<T>;

    function Reverse: Stream<T>;

    function Skip(aCount: integer): Stream<T>;

    function SkipWhile(aPredicate: TPredicate<T>): Stream<T>;

    function TakeWhile(aPredicate: TPredicate<T>): Stream<T>;

    function Sort(aComparer: IComparer<T> = nil): Stream<T>;

    function Distinct(aComparer: IEqualityComparer<T> = nil): Stream<T>; overload;

    function Distinct<U>(const aIdGen: TFunc<T, U>): Stream<T>; overload;

    function Union(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil): Stream<T>; overload;

    function Union<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>; overload;

    function Difference(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil): Stream<T>; overload;

    function Difference<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>; overload;

    function Intersect(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil): Stream<T>; overload;

    function Intersect<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>; overload;

    function Concat(const aItems: array of T): Stream<T>; overload;

    function Concat(const [ref] aStream: Stream<T>): Stream<T>; overload;

    function Remove(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil): Stream<T>; overload;

    function Remove<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>; overload;

    { initialization operations }

    procedure InitializeFrom(const aItems: TEnumerable<T>); overload;

    procedure InitializeFrom(const aItems: array of T); overload;

    class function From(const aItems: TEnumerable<T>): Stream<T>; overload; static;

    class function From(const aItems: array of T): Stream<T>; overload; static;

    class function Range(aStart: integer; aEnd: integer; aStep: integer = 1): Stream<integer>; static;

    class function Random(aStart: integer; aEnd: integer; aCount: integer): Stream<integer>; static;

    class function Produce(const aValue: T; aCount: integer): Stream<T>; static;

    { class operators }

    class operator Initialize (out Dest: Stream<T>);

    class operator Finalize(var Dest: Stream<T>);
  end;

  StreamExtensions = class
  public
    class function GroupBy<T>(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil): TDictionary<T, TList<T>>; overload;

    class function GroupBy<T>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T,string>; aIgnoreCase: boolean = true): TDictionary<string, TList<T>>; overload;

    class function Max<T>(const [ref] aStream: Stream<T>; aComparer: IComparer<T> = nil): T;

    class function Min<T>(const [ref] aStream: Stream<T>; aComparer: IComparer<T> = nil): T;

    class function ToMap<T>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, string>; aIgnoreCase: boolean = true; aOwns: TDictionaryOwnerships = []): TObjectDictionary<string, T>; overload;

    class procedure Difference<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>); overload;

    class procedure Difference<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T> = nil); overload;

    class procedure Distinct<T, U>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>); overload;

    class procedure Distinct<T>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T> = nil); overload;

    class procedure Intersect<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>); overload;

    class procedure Intersect<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T> = nil); overload;

    class procedure Remove<T, U>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; const [ref] aRemoveStream: Stream<T>; const aIdGen: TFunc<T, U>); overload;

    class procedure Remove<T>(const [ref] aResult: Stream<T>;const [ref] aStream: Stream<T>; const [ref] aRemoveStream: Stream<T>; aComparer: IEqualityComparer<T> = nil); overload;

    class procedure Union<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>); overload;

    class procedure Union<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T> = nil); overload;
  end;

const
  INIT_ERROR = 'stream has already been initialized';

implementation

uses
  System.Math,
  SharedKernel.Containers;

{ Stream<T> }

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Concat(const [ref] aStream: Stream<T>): Stream<T>;
begin
  Result.fList.AddRange(fList);
  Result.fList.AddRange(aStream.fList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Concat(const aItems: array of T): Stream<T>;
begin
  Result.fList.AddRange(fList);
  Result.fList.AddRange(aItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Distinct(aComparer: IEqualityComparer<T>): Stream<T>;
begin
  StreamExtensions.Distinct<T>(Result, Self, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Distinct<U>(const aIdGen: TFunc<T, U>): Stream<T>;
begin
  StreamExtensions.Distinct<T, U>(Result, Self, aIdGen);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Union(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>): Stream<T>;
begin
  StreamExtensions.Union<T>(Result, Self, aStream, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Union<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>;
begin
  StreamExtensions.Union<T,U>(Result, Self, aStream, aIdGen);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Difference(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>): Stream<T>;
begin
  StreamExtensions.Difference<T>(Result, Self, aStream, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Difference<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>;
begin
  StreamExtensions.Difference<T, U>(Result, Self, aStream, aIdGen);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Intersect(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>): Stream<T>;
begin
  StreamExtensions.Intersect<T>(Result, Self, aStream, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Intersect<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>;
begin
  StreamExtensions.Intersect<T, U>(Result, Self, aStream, aIdGen);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.AllMatch(aPredicate: TPredicate<T>): boolean;
var
  lItem: T;
begin
  for lItem in fList do
    if not aPredicate(lItem) then exit(false);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.AnyMatch(aPredicate: TPredicate<T>): boolean;
var
  lItem: T;
begin
  for lItem in fList do
    if aPredicate(lItem) then exit(true);

  Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Count: integer;
begin
  Result := fList.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.First: T;
const
  NOT_FOUND = 'item not found';
begin
  if fList.Count > 0 then exit(fList[0]);

  raise Exception.Create(NOT_FOUND);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.First(aPredicate: TPredicate<T>): T;
const
  NOT_FOUND = 'item not found';
var
  lItem: T;
begin
  for lItem in fList do
    if aPredicate(lItem) then exit(lItem);

  raise Exception.Create(NOT_FOUND);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.FirstOrDefault: T;
begin
  if fList.Count > 0 then exit(fList[0]);

  Result := default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.FirstOr(aDefault: T): T;
begin
  if fList.Count > 0 then exit(fList[0]);

  Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.FirstOrDefault(aPredicate: TPredicate<T>): T;
var
  lItem: T;
begin
  for lItem in fList do
    if aPredicate(lItem) then exit(lItem);

  Result := default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Last: T;
const
  NOT_FOUND = 'item not found';
begin
  if fList.Count > 0 then exit(fList[Pred(fList.Count)]);

  raise Exception.Create(NOT_FOUND);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Last(aPredicate: TPredicate<T>): T;
const
  NOT_FOUND = 'item not found';
var
  i: integer;
  n: integer;
  lItem: T;
begin
  n := Pred(fList.Count);

  for i := n DownTo 0 do
  begin
    lItem := fList[i];
    if aPredicate(lItem) then exit(lItem);
  end;

  raise Exception.Create(NOT_FOUND);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.LastOrDefault: T;
begin
  if fList.Count > 0 then exit(fList[Pred(fList.Count)]);

  Result := default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.LastOrDefault(aPredicate: TPredicate<T>): T;
var
  i: integer;
  n: integer;
  lItem: T;
begin
  n := Pred(fList.Count);

  for i := n DownTo 0 do
  begin
    lItem := fList[i];
    if aPredicate(lItem) then exit(lItem);
  end;

  Result := default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToArray: TArray<T>;
begin
  Result := fList.ToArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToList: TList<T>;
begin
  Result := TList<T>.Create(fList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToMap<U>: TDictionary<T, U>;
var
  lItem: T;
  lValue: U;
begin
  Result := TDictionary<T, U>.Create;

  lValue := default(U);

  for lItem in fList do
    Result.Add(lItem, lValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToMap<U>(const aValueGen: TFunc<T, U>): TDictionary<T, U>;
var
  lItem: T;
begin
  Result := TDictionary<T, U>.Create;

  for lItem in fList do
    Result.Add(lItem, aValueGen(lItem));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToMap<K, V>(const aGen: TFunc<T, TPair<K,V>>): TDictionary<K, V>;
var
  lItem: T;
  lPair:  TPair<K,V>;
begin
  Result := TDictionary<K, V>.Create;

  for lItem in fList do
  begin
    lPair := aGen(lItem);
    Result.Add(lPair.Key, lPair.Value);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToMap<U>(const aIdGen: TFunc<T, U>; aOwns: TDictionaryOwnerships): TObjectDictionary<U, T>;
var
  lItem: T;
  lKey: U;
begin
  Result := TObjectDictionary<U, T>.Create(aOwns);

  for lItem in fList do
  begin
    lKey := aIdGen(lItem);
    Result.Add(lKey, LItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.ToMap(const aIdGen: TFunc<T, string>; aIgnoreCase: boolean; aOwns: TDictionaryOwnerships): TObjectDictionary<string, T>;
begin
  Result := StreamExtensions.ToMap<T>(Self, aIdGen, aIgnoreCase, aOwns);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.GroupBy(aComparer: IEqualityComparer<T>): TDictionary<T, TList<T>>;
begin
  Result := StreamExtensions.GroupBy<T>(Self, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.GroupBy(const aIdGen: TFunc<T, string>; aIgnoreCase: boolean): TDictionary<string, TList<T>>;
begin
  Result := StreamExtensions.GroupBy<T>(Self, aIdGen, aIgnoreCase);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.GroupBy<U>(const aIdGen: TFunc<T, U>): TDictionary<U, TList<T>>;
var
  lItem: T;
  lKey: U;
begin
  Result := TDictionary<U, TList<T>>.Create;

  for lItem in fList do
  begin
    lKey := aIdGen(lItem);

    if not Result.ContainsKey(lKey) then
      Result.Add(lKey, TList<T>.Create);

    Result[lKey].Add(lItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream<T>.ForEach(aConsumer: TProc<T>);
var
  lItem: T;
begin
  for lItem in fList do
    aConsumer(lItem);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream<T>.Apply(aConsumer: TProcvar<T>);
var
  i: integer;
  lItem: T;
begin
  for i := 0 to Pred(fList.Count) do
  begin
    lItem := fList[i];
    aConsumer(lItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Filter(aPredicate: TPredicate<T>): Stream<T>;
var
  lItem: T;
begin
  for lItem in fList do
    if aPredicate(lItem) then
      Result.fList.Add(lItem);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Map<U>(aMapper: TFunc<T, U>): Stream<U>;
var
  lItem: T;
begin
  for lItem in fList do
    Result.fList.Add(aMapper(lItem));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Min(aComparer: IComparer<T>): T;
begin
  Result := StreamExtensions.Min<T>(Self, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Max(aComparer: IComparer<T>): T;
begin
  Result := StreamExtensions.Max<T>(Self, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Peek(aConsumer: TProc<T>): Stream<T>;
var
  lItem: T;
begin
  for lItem in fList do
    aConsumer(lItem);

  Result.fList.AddRange(fList);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream<T>.Produce(const aValue: T; aCount: integer): Stream<T>;
var
  i: integer;
begin
  for i := 0 to Pred(aCount) do
    Result.fList.Add(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Reduce<U>(aValue: U; const reducer: TFunc<U, T, U>): U;
var
  lItem: T;
begin
  for lItem in fList do
    aValue := reducer(aValue, lItem);

  Result := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Remove(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>): Stream<T>;
begin
  StreamExtensions.Remove<T>(Result, Self, aStream, aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Remove<U>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>): Stream<T>;
begin
  StreamExtensions.Remove<T, U>(Result, Self, aStream, aIdGen);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Reverse: Stream<T>;
begin
  fList.Reverse;
  Result.fList.AddRange(fList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Skip(aCount: integer): Stream<T>;
var
  i: integer;
begin
  if aCount >= fList.Count then exit;

  for i := aCount to Pred(fList.Count) do
    Result.fList.Add(fList[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.SkipWhile(aPredicate: TPredicate<T>): Stream<T>;
var
  lItem: T;
  lIgnoring: boolean;
begin
  lIgnoring := true;

  for lItem in fList do
  begin
    if lIgnoring then
    begin
      if aPredicate(lItem) then continue;
      lIgnoring := false;
    end;

    Result.fList.Add(lItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.TakeWhile(aPredicate: TPredicate<T>): Stream<T>;
var
  lItem: T;
begin
  for lItem in fList do
  begin
    if not aPredicate(lItem) then exit;
    Result.fList.Add(lItem)
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Sort(aComparer: IComparer<T>): Stream<T>;
begin
  if not Assigned(aComparer) then
    aComparer := TComparer<T>.Default;

  fList.Sort(aComparer);
  Result.fList.AddRange(fList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream<T>.Limit(aCount: integer): Stream<T>;
var
  i: integer;
  n: integer;
begin
  n := System.Math.Min(aCount, fList.Count) - 1;

  for i := 0 to n do
    Result.fList.Add(fList[i]);
end;

//{----------------------------------------------------------------------------------------------------------------------}
class function Stream<T>.From(const aItems: array of T): Stream<T>;
begin
  Result.fList.AddRange(aItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream<T>.From(const aItems: TEnumerable<T>): Stream<T>;
begin
  Result.fList.AddRange(aItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream<T>.Range(aStart, aEnd, aStep: integer): Stream<integer>;
var
  i: integer;
begin
  i := aStart;

  while i <> aEnd do
  begin
    Result.fList.Add(i);
    Inc(i, aStep);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream<T>.Random(aStart, aEnd, aCount: integer): Stream<integer>;
var
  i: integer;
  r: integer;
  hours, mins, secs, milliSecs : Word;
begin
  DecodeTime(now, hours, mins, secs, milliSecs);
  RandSeed := milliSecs;

  i := 0;

  while i <> aCount do
  begin
    r := RandomRange(aStart, aEnd);
    Result.fList.Add(r);
    Inc(i);
  end;
end;

//{----------------------------------------------------------------------------------------------------------------------}
procedure Stream<T>.InitializeFrom(const aItems: array of T);
begin
  Expect.IsEmpty<T>(fList, INIT_ERROR);

  fList.AddRange(aItems);
end;

//{----------------------------------------------------------------------------------------------------------------------}
procedure Stream<T>.InitializeFrom(const aItems: TEnumerable<T>);
begin
  fList.AddRange(aItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator Stream<T>.Initialize(out Dest: Stream<T>);
begin
  Dest.fList := TList<T>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator Stream<T>.Finalize(var Dest: Stream<T>);
begin
  Dest.fList.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Difference<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>);
var
  lMatches: TDictionary<U, TPair<integer, T>>;
  lPair: TPair<integer, T>;
  lItem: T;
  lKey: U;
begin
   lMatches := TDictionary<U, TPair<integer, T>>.Create;

  try
    { add distinct items from the first list to the matches map }
    for lItem in aFirst.fList do
    begin
      lKey := aIdGen(lItem);

      if not lMatches.ContainsKey(lKey) then
        lMatches.Add(lKey, TPair<integer, T>.Create(1, lItem));
    end;

    { try to identify matches between the map and the second list }
    for lItem in aSecond.fList do
    begin
      lKey := aIdGen(lItem);

      if not lMatches.ContainsKey(lKey) then
        lMatches.Add(lKey, TPair<integer, T>.Create(0, lItem))
      else if lMatches[lKey].Key = 1 then
        lMatches[lKey] := TPair<integer, T>.Create(2, lItem);
    end;

    for lPair in lMatches.Values do
      if lPair.Key < 2 then
        aResult.fList.Add(lPair.Value);

  finally
    lMatches.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Difference<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T>);
var
  lMatches: TDictionary<T, integer>;
  lPair: TPair<T, integer>;
  lItem: T;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  lMatches := TDictionary<T, integer>.Create(aComparer);

  try
    { add distinct items from the first list to the matches map }
    for lItem in aFirst.fList do
      if not lMatches.ContainsKey(lItem) then
        lMatches.Add(lItem, 1);

    { try to identify matches between the map and the second list }
    for lItem in aSecond.fList do
    begin
      if not lMatches.ContainsKey(lItem) then
        lMatches.Add(lItem, 0)
      else if lMatches[lItem] = 1 then
        lMatches[lItem] := 2;
    end;

    for lPair in lMatches do
      if lPair.Value < 2 then
        aResult.fList.Add(lPair.Key);

  finally
    lMatches.Free;
  end;

end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Distinct<T, U>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, U>);
var
  lItem: T;
  lKey: U;
  lSeen: TDictionary<U, boolean>;
begin
  lSeen := TDictionary<U, boolean>.Create;

  try
    for lItem in aStream.fList do
    begin
      lKey := aIdGen(lItem);

      if not lSeen.ContainsKey(lKey) then
      begin
        lSeen.Add(lKey, true);
        aResult.fList.Add(lItem);
      end;
    end;
  finally
    lSeen.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Distinct<T>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>);
var
  lItem: T;
  lSeen: TDictionary<T, boolean>;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  lSeen := TDictionary<T, boolean>.Create(aComparer);
  try
    for lItem in aStream.fList do
      if not lSeen.ContainsKey(lItem) then
      begin
        lSeen.Add(lItem, true);
        aResult.fList.Add(lItem);
      end;
  finally
    lSeen.Free;
  end;
end;

{ StreamExtensions }

{----------------------------------------------------------------------------------------------------------------------}
class function StreamExtensions.GroupBy<T>(const [ref] aStream: Stream<T>; aComparer: IEqualityComparer<T>): TDictionary<T, TList<T>>;
var
  lItem: T;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  Result := TDictionary<T, TList<T>>.Create(aComparer);

  for lItem in aStream.fList do
  begin
    if not Result.ContainsKey(lItem) then
      Result.Add(lItem, TList<T>.Create);

    Result[lItem].Add(lItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function StreamExtensions.GroupBy<T>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, string>; aIgnoreCase: boolean): TDictionary<string, TList<T>>;
var
  lItem: T;
  lKey: string;
begin
  if aIgnoreCase then
    Result := TDictionary<string, TList<T>>.Create(TIStringComparer.Ordinal)
  else
    Result := TDictionary<string, TList<T>>.Create;

  for lItem in aStream.fList do
  begin
    lKey := aIdGen(lItem);

    if not Result.ContainsKey(lKey) then
      Result.Add(lKey, TList<T>.Create);

    Result[lKey].Add(lItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Intersect<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>);
var
  lSmallest: TList<T>;
  lLargest: TList<T>;
  lMatches: TDictionary<U, TPair<integer, T>>;
  lPair: TPair<integer, T>;
  lItem: T;
  lKey: U;
begin
  { determine the smallest list of numbers }
  if aFirst.fList.Count > aSecond.fList.Count then
  begin
    lLargest  := aFirst.fList;
    lSmallest := aSecond.fList;
  end
  else
  begin
    lSmallest := aFirst.fList;
    lLargest  := aSecond.fList;
  end;

  lMatches := TDictionary<U, TPair<integer, T>>.Create;

  try
    { add distinct items from the first list to the matches map }
    for lItem in lSmallest do
    begin
      lKey := aIdGen(lItem);

      if not lMatches.ContainsKey(lKey) then
        lMatches.Add(lKey, TPair<integer, T>.Create(1, lItem));
    end;

    { try to identify matches between the map and the second list }
    for lItem in lLargest do
    begin
      lKey := aIdGen(lItem);

      if lMatches.ContainsKey(lKey) then
        if lMatches[lKey].Key = 1 then
          lMatches[lKey] := TPair<integer, T>.Create(2, lItem);
    end;

    for lPair in lMatches.Values do
      if lPair.Key = 2 then
        aResult.fList.Add(lPair.Value);

  finally
    lMatches.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Intersect<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T>);
var
  lSmallest: TList<T>;
  lLargest:  TList<T>;
  lMatches: TDictionary<T, integer>;
  lPair: TPair<T, integer>;
  lItem: T;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  { determine the smallest list of numbers }
  if aFirst.fList.Count > aSecond.fList.Count then
  begin
    lLargest  := aFirst.fList;
    lSmallest := aSecond.fList;
  end
  else
  begin
    lSmallest := aFirst.fList;
    lLargest  := aSecond.fList;
  end;

  lMatches := TDictionary<T, integer>.Create(aComparer);

  try
    { add distinct items from the first list to the matches map }
    for lItem in lSmallest do
    begin
      if not lMatches.ContainsKey(lItem) then
        lMatches.Add(lItem, 1);
    end;

    { try to identify matches between the map and the second list }
    for lItem in lLargest do
    begin
      if lMatches.ContainsKey(lItem) then
        if lMatches[lItem] = 1 then
          lMatches[lItem] := 2;
    end;

    for lPair in lMatches do
      if lPair.Value = 2 then
        aResult.fList.Add(lPair.Key);
  finally
    lMatches.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function StreamExtensions.Max<T>(const [ref] aStream: Stream<T>; aComparer: IComparer<T>): T;
var
  lItem: T;
  i: integer;
begin
  if not Assigned(aComparer) then
    aComparer := TComparer<T>.Default;

  if aStream.fList.Count = 0 then exit(default(T));
  if aStream.fList.Count = 1 then exit(aStream.fList[0]);

  Result := aStream.fList[0];

  for i := 1 to Pred(aStream.fList.Count) do
  begin
    lItem := aStream.fList[i];

    if aComparer.Compare(lItem, Result) > 0 then
      Result := lItem;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function StreamExtensions.Min<T>(const [ref] aStream: Stream<T>; aComparer: IComparer<T>): T;
var
  lItem: T;
  i: integer;
begin
  if not Assigned(aComparer) then
    aComparer := TComparer<T>.Default;

  if aStream.fList.Count = 0 then exit(default(T));
  if aStream.fList.Count = 1 then exit(aStream.fList[0]);

  Result := aStream.fList[0];

  for i := 1 to Pred(aStream.fList.Count) do
  begin
    lItem := aStream.fList[i];

    if aComparer.Compare(lItem, Result) < 0 then
      Result := lItem;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Remove<T, U>(const [ref] aResult: Stream<T>; const [ref] aStream: Stream<T>; const [ref] aRemoveStream: Stream<T>; const aIdGen: TFunc<T, U>);
var
  lRemoved: TDictionary<U, boolean>;
  lItem: T;
  lKey: U;
begin
  lRemoved := TDictionary<U, boolean>.Create;

  try
    for lItem in aRemoveStream.fList do
    begin
      lKey := aIdGen(lItem);

      if not lRemoved.ContainsKey(lKey) then
        lRemoved.Add(lKey, true);
    end;

    for lItem in aStream.fList do
    begin
      lKey := aIdGen(lItem);

      if not lRemoved.ContainsKey(lKey) then
        aResult.fList.Add(lItem);
    end;
  finally
    lRemoved.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Remove<T>(const [ref] aResult: Stream<T>;const [ref] aStream: Stream<T>; const [ref] aRemoveStream: Stream<T>; aComparer: IEqualityComparer<T> = nil);
var
  lRemoved: TDictionary<T, boolean>;
  lItem: T;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  lRemoved := TDictionary<T, boolean>.Create(aComparer);

  try
    for lItem in aRemoveStream.fList do
    begin
      if not lRemoved.ContainsKey(lItem) then
        lRemoved.Add(lItem, true);
    end;

    for lItem in aStream.fList do
      if not lRemoved.ContainsKey(lItem) then
        aResult.fList.Add(lItem);
  finally
    lRemoved.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function StreamExtensions.ToMap<T>(const [ref] aStream: Stream<T>; const aIdGen: TFunc<T, string>; aIgnoreCase: boolean; aOwns: TDictionaryOwnerships): TObjectDictionary<string, T>;
var
  lItem: T;
  lKey: string;
begin
  if aIgnoreCase then
    Result := TObjectDictionary<string, T>.Create(aOwns, TIStringComparer.Ordinal)
  else
    Result := TObjectDictionary<string, T>.Create(aOwns);

  for lItem in aStream.fList do
  begin
    lKey := aIdGen(lItem);
    Result.Add(lKey, LItem);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Union<T, U>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; const aIdGen: TFunc<T, U>);
var
  lMatches: TDictionary<U, T>;
  lItem: T;
  lKey: U;
begin
  lMatches := TDictionary<U, T>.Create;

  try
    { add distinct items from the first list to the matches map }
    for lItem in aFirst.fList do
    begin
      lKey := aIdGen(lItem);

      if not lMatches.ContainsKey(lKey) then
        lMatches.Add(lKey, lItem);
    end;

    { add distinct items from the second list to the matches map }
    for lItem in aSecond.fList do
    begin
      lKey := aIdGen(lItem);

      if not lMatches.ContainsKey(lKey) then
        lMatches.Add(lKey, lItem);
    end;

    aResult.fList.AddRange(lMatches.Values);

  finally
    lMatches.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure StreamExtensions.Union<T>(const [ref] aResult: Stream<T>; const [ref] aFirst: Stream<T>; const [ref] aSecond: Stream<T>; aComparer: IEqualityComparer<T>);
var
  lMatches: TDictionary<T, boolean>;
  lItem: T;
begin
  if not Assigned(aComparer) then
    aComparer := TEqualityComparer<T>.Default;

  lMatches := TDictionary<T, boolean>.Create(aComparer);

  try
    { add distinct items from the first list to the matches map }
    for lItem in aFirst.fList do
      if not lMatches.ContainsKey(lItem) then
        lMatches.Add(lItem, true);

    { add distinct items from the second list to the matches map }
    for lItem in aSecond.fList do
      if not lMatches.ContainsKey(lItem) then
        lMatches.Add(lItem, true);

    aResult.fList.AddRange(lMatches.Keys);

  finally
    lMatches.Free;
  end;
end;

end.
