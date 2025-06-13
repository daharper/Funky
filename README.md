# Funky
Recently I began a new Delphi project using Clean Architecture. Whilst scaffolding to support this architecture, I experimented with implementing some functional programming concepts.

I was possible to accomplish much, but Delphi’s power lies in **clarity**, **predictability**, and **getting out of your way** — not in imitating languages with deeply expressive type systems like Haskell, F#, or Scala.

## The  Good

Some things worked out very well.

### Stream

Stream is a poor man's imitation of Java's powerhouse, but it is extremely useful, allowing you to filter, map, reduce, group, and combine data in a clean and expressive way, using generics and lambdas.

#### Key Features

- Stream creation from arrays, lists, ranges, or generators
- Functional-style operations: `filter`, `map`, `reduce`, `distinct`, etc.
- Set operations: `union`, `intersect`, `difference`, `remove`
- Grouping and dictionary mapping
- Supports both value and reference types

I love using a declarative approach, and look forwards to refactoring and further improving this class.

The following is a list of currently supported methods:

#### Initialization Methods

| Method                           | Description                                                                   |
| -------------------------------- | ----------------------------------------------------------------------------- |
| `InitializeFrom(array)`          | Initializes the stream with array contents (once only)                        |
| `InitializeFrom(TEnumerable<T>)` | Initializes the stream with an enumerable collection                          |
| `From(array)`                    | Creates a new stream from an array                                            |
| `From(TEnumerable<T>)`           | Creates a new stream from an enumerable                                       |
| `Range(start, end, step)`        | Creates a stream of integers from `start` to `end` (exclusive) with step size |
| `Random(start, end, count)`      | Creates a stream of random integers                                           |
| `Produce(value, count)`          | Repeats a value `count` times into the stream                                 |


#### Terminating Operations

| Method                                    | Description                                                       |
| ----------------------------------------- | ----------------------------------------------------------------- |
| `Count()`                                 | Returns the number of elements                                    |
| `AnyMatch(predicate)`                     | Returns `true` if any element matches the predicate               |
| `AllMatch(predicate)`                     | Returns `true` if all elements match the predicate                |
| `ToList()`                                | Materializes the stream into a new `TList<T>`                     |
| `ToArray()`                               | Materializes the stream into a `TArray<T>`                        |
| `Reduce(value, reducer)`                  | Reduces the stream into a single value using the reducer function |
| `Min(comparer?)`                          | Finds the minimum element using optional comparer                 |
| `Max(comparer?)`                          | Finds the maximum element using optional comparer                 |
| `ToMap<K,V>(pairGenerator)`               | Transforms elements to `TPair<K,V>` and builds dictionary         |
| `ToMap<U>()`                              | Maps each item as key, default value `default(U)`                 |
| `ToMap<U>(valueGenerator)`                | Maps each item as key to value via generator                      |
| `ToMap<U>(keyGenerator, owns)`            | Maps with object dictionary using key generator                   |
| `ToMap(stringKeyGen, ignoreCase?, owns?)` | Maps to `TObjectDictionary<string,T>`                             |
| `GroupBy(comparer?)`                      | Groups items by identity using optional comparer                  |
| `GroupBy<U>(keyGenerator)`                | Groups by transformed keys                                        |
| `GroupBy(stringKeyGen, ignoreCase?)`      | Groups by string key                                              |
| `First()`                                 | Returns first item or raises if empty                             |
| `First(predicate)`                        | Returns first matching item or raises if none                     |
| `FirstOr(default)`                        | Returns first item or fallback default                            |
| `FirstOrDefault()`                        | Returns first item or `default(T)`                                |
| `FirstOrDefault(predicate)`               | Returns first match or `default(T)`                               |
| `Last()`                                  | Returns last item or raises if empty                              |
| `Last(predicate)`                         | Returns last match or raises                                      |
| `LastOrDefault()`                         | Returns last or `default(T)`                                      |
| `LastOrDefault(predicate)`                | Returns last matching item or `default(T)`                        |
| `ForEach(action)`                         | Performs an action for each element                               |
| `Apply(procvar)`                          | Runs a `var`-style procedure on each item                         |


#### Transforming Operations

| Method                          | Description                                                        |
| ------------------------------- | ------------------------------------------------------------------ |
| `Filter(predicate)`             | Filters the stream with the predicate                              |
| `Limit(count)`                  | Returns only the first `count` elements                            |
| `Map<U>(mapper)`                | Transforms each element using `mapper`                             |
| `Peek(consumer)`                | Executes side effect for each item, passes through original stream |
| `Reverse()`                     | Reverses the order of elements                                     |
| `Skip(count)`                   | Skips first `count` elements                                       |
| `SkipWhile(predicate)`          | Skips elements while predicate is true                             |
| `TakeWhile(predicate)`          | Takes elements while predicate is true                             |
| `Sort(comparer?)`               | Sorts the stream using comparer or default                         |
| `Distinct(comparer?)`           | Removes duplicates using optional comparer                         |
| `Distinct<U>(keyGen)`           | Removes duplicates by derived key                                  |
| `Union(stream, comparer?)`      | Combines unique elements from both streams                         |
| `Union<U>(stream, keyGen)`      | Combines unique elements by derived key                            |
| `Difference(stream, comparer?)` | Returns items in first stream not in second                        |
| `Difference<U>(stream, keyGen)` | Difference based on derived key                                    |
| `Intersect(stream, comparer?)`  | Returns intersection of two streams                                |
| `Intersect<U>(stream, keyGen)`  | Intersection by derived key                                        |
| `Concat(array)`                 | Appends items to current stream                                    |
| `Concat(stream)`                | Appends another stream’s elements                                  |
| `Remove(stream, comparer?)`     | Removes matching items from stream                                 |
| `Remove<U>(stream, keyGen)`     | Removes items based on key identity                                |

As a managed record, its resources are automatically cleaned up.

#### Examples

Create a Stream:

```pascal
var stream := Stream<Integer>.From([1, 2, 3, 4, 5]);
```

Chaining Functions:

```pascal
var names := Stream<string>
  .From(['Tyson', 'Canelo', 'GGG', 'Jones', 'GGG', 'Hatton', 'Usyk', 'Usyk'])
  .Remove(Stream<string>.From(['Tyson', 'Jones', 'Hatton']))
  .Distinct
  .Sort(TIStringComparer.Ordinal)
  .Reverse
  .ToArray;
```

Please see **Tests.Streams** for more examples.

### Specifications

The Specification Pattern encapsulates business rules into reusable, composable objects.

#### Key Features

- Reusable business logic
- Composable with `.AndAlso`, `.OrElse`, `.NotThis`
- Testable in isolation

#### Examples

The interface section:

```pascal
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
```
And the implementation:
```pascal
  constructor TDepartmentIs.Create(const Dept: string);
  begin
    fDept := Dept;
  end;

  function TDepartmentIs.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
  begin
    Result := Candidate.Department = fDept;
  end;
 
  constructor TSalaryAbove.Create(Threshold: Integer);
  begin
    fThreshold := Threshold;
  end;

  function TSalaryAbove.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
  begin
    Result := Candidate.Salary > fThreshold;
  end;

  constructor TSaleSectionIs.Create(const Section: string);
  begin
    fSection := Section;
  end;
```

Usage:

```pascal
var spec := TDepartmentIs.Create('IT').AndAlso(TSalaryAbove.Create(68000));

for c in fCustomers do
  if spec.IsSatisfiedBy(c) then
    ShowMessage(c.Name);
```

### Scope

A simple way to avoid try/finally/free blocks in your code.

#### Examples

This example from **Tests.Core** demonstrates two instances of the class TLanguage being cleaned up automatically. TLanguage is a regular class, it is not reference counted:

```pascal
procedure TCoreTests.Scope_Test;
var
  scope: TScope;
begin
  var delphi  := scope.Add(TLanguage.Create('Delphi'));
  var csharp  := scope.Add(TLanguage.Create('CSharp'));

  Assert.AreEqual('Delphi', delphi.Name);
  Assert.AreEqual('CSharp', csharp.Name);

  { memory leak reporting is on, shouldn't throw a leak error }
end;
```

### Lazy

Defer evaluation of a method until the value is requested.

#### Examples

Also from **Tests.Core**:

```pascal
lazy := TLazy<Integer>.Create(
    function: Integer
    begin
      Result := 123;
    end);

Assert.IsFalse(lazy.IsEvaluated, 'Expected IsEvaluated to be False initially');
Assert.AreEqual(123, lazy.Value);
Assert.IsTrue(lazy.IsEvaluated, 'Expected IsEvaluated to be True after evaluation');
```

### TMaybe

An optional value monad, representing a value that may or may not exist. Deliberately kept simple.

#### Key Features

- No need to check for `nil` or invalid values
- Clearer API for optional data
- Works well with functions returning optional results

| Method             | Description                               |
| ------------------ | ----------------------------------------- |
| `IsSome`           | True if value is present                  |
| `IsNone`           | True if value is absent                   |
| `Value`            | Gets the value, raises if `None`          |
| `OrElse(fallback)` | Returns value or fallback                 |
| `OrElseGet(func)`  | Returns value or computes fallback lazily |
| `Some(value)`      | Creates a present value                   |
| `None`             | Creates an absent value                   |

#### Examples

Simple assignment:

```pascal
maybe := TMaybe<string>.Some('Delphi');

if maybe.IsSome then
  ShowMessage(maybe.Value);
```

Default fallback:

```pascal
maybe := TMaybe<string>.None;
ShowMessage(maybe.OrElse('Default')); 
```

Lazy fallback:

```pascal
maybe := TMaybe<string>.None;
ShowMessage(maybe.OrElseGet(function: string begin Result := 'Lazy'; end));
```

### TResult

The simple use cases of this fully functional result monad worked well, and fit well in Delphi.

#### Key Features

- Explicit success/failure path
- Safer than exceptions for expected errors
- Enables clean return values from service layers

| Property/Method | Description                          |
| --------------- | ------------------------------------ |
| `IsOk`          | True if success                      |
| `IsErr`         | True if error                        |
| `Value`         | Gets the value (raises if error)     |
| `Error`         | Gets the error message (empty if Ok) |
| `Ok(value)`     | Constructs a successful result       |
| `Err(msg)`      | Constructs a failed result           |

#### Examples

Success case:

```pascal
var res := TResult<string>.Ok('Success');

if res.IsOk then
  ShowMessage(res.Value); // Success
```

Error case:

```pascal
var res := TResult<Integer>.Err('Invalid input');

if res.IsErr then
  ShowMessage(res.Error); // Invalid input
```

## The Okay

The DI Container. This was my first in Delphi and it was quite the effort. The second will be designed better.

Although it is rather spartan, and limited, it is performing well enough. 

It distinguishes between two types:

- TSingleton - container managed type
- TTransient - reference counted

```pascal
TWorldBuilder = class(TSingleton, IWorldBuilder)
	// ...
end;

TClassificationProfile = class(TTransient, IClassificationProfile)
	// ...
end;
```

I used these types because I didn't want the user to worry about memory management, just ask for a type, use it, forget about it. I especially didn't want the user to accidentally free a Singleton managed by the container. This decision established the contract: *all types must be registered against an interface*. This is something I'll reconsider in the future.

To improve performance, singleton and transient types are identified and cached on initialization.

#### Examples

Registering services:

```pascal
 Container.AddServices([
	TGameSession,
	TWorldBuilder,
	TWorldEngine,
	TClassificationProfile,
	TTextParser,
	TConsole,
	TConsolePlayerPresenter,
	TConsoleWorldPresenter
]);
```

A service receiving dependencies via constructor injections:

```pascal
constructor TConsole.Create(
	aParser: ITextParser;
	aPlayerPresenter: IPlayerPresenter;
	aWorldPresenter: IWorldPresenter;
	aStartGameUseCase: IStartGameUseCase;
	aDispatcher: ICommandDispatcher;
	aWorldEngine: IWorldEngine);
```

## The Bad

Delphi just isn't designed as a first class functional language, the fact that you can actually implement fully functional monads is a testament to its power and flexibility. It really shines when used as intended. Fully functional constructs become such an exercise in beat-the-compiler, and verbosity, that they offer very little benefit. This is an example of using the **Zip** function:

```pascal
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

```

There's so much noise, it's unnecessarily complex.

Many methods have been implemented, including the following and more:

| Method                           | Description                      |
| -------------------------------- | -------------------------------- |
| `.Map(func)`                     | Transforms value                 |
| `.Bind(func)`                    | Chains result-producing function |
| `.Apply(funcRes)`                | Applies function in a result     |
| `.Zip(other, func)`              | Combines two results             |
| `.SelectMany(binder, projector)` | LINQ-style flat map              |
| `.Ensure(predicate, msg)`        | Validates value                  |
| `.Tap(action)`                   | Executes side-effect on success  |
| `.TapError(action)`              | Side-effect on error             |
| `.Recover(func)`                 | Replaces error with fallback     |
| `.MapError(func)`                | Transforms error message         |
| `.OrElse(fallback)`              | Supplies alternate result        |
| `.Match(onOk, onErr)`            | Pattern match style              |
| `.Log(tag)`                      | Logs current state               |

The **Tests.Result.Complex.pas** file contains a number of unit tests demonstrating a some of the functions.

The **TResult** tests were split into two, to highlight the distinction in complexity. **SharedKernel.Core.pas** will similarly have the more complex functions split out to a helper unit in the near future.

## The Project

The project is a **DUnitX** test project. 

There are four core files:

- SharedKernel.Container.pas   
- SharedKernel.Core.pas          
- SharedKernel.Specifications.pas
- SharedKernel.Streams.pas

The rest of the code is in half a dozen tests and a couple of simple mock objects.    

I defined **TESTINSIGHT** in the **.dpr**:

```pascal
{$DEFINE TESTINSIGHT}
```

There's an overview of **TestInsight** [here](https://delphisorcery.blogspot.com/2021/04/testinsight-12-released.html) from where you can download and install it - highly recommended, it is excellent. Once **TestInisight** is installed, you can run or debug the tests as per normal.

![image-20250613202917759](https://github.com/user-attachments/assets/8d0236e3-e62d-4bde-9870-914ce655cff3)

## Whats Next

This was an interesting project, I learned a lot. Some things turned out better than expected, such as the **Stream** type. That's one type I'll be improving and using in projects moving forwards.

This was a good exercise to seek a deeper understanding of the RTTI and Generics. I remember struggling trying to use generics to solve a problem, and nothing would work. Even **array of const** and **Variants** were of no use - one can't accept enum and interface arguments, the other loses interface type information. Success came when I stopped trying to fight the compiler, and to think differently.

Such a beautiful expression was waiting to be discovered:

```pascal
Player.Intent(TMoveIntentEvent)
    .Add(lCurrentRoom)
    .Add(aDirection)
    .Declare;
```

and:

```pascal
Result := TStoneBuilder.New
      .Weight(RandomRange(1, 5))
      .Texture(lTexture)
      .Sharpness(RandomRange(0, 2))
      .InRoom(Room)
      .Realize;
```

For a feature rich battle hardened framework, I highly recommend checking out [Spring4D](https://learndelphi.org/everything-you-need-to-know-about-spring4d-delphi-development-framework/). 

