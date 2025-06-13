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

High-earning IT customers:

```pascal
type
  TDepartmentIs = class(TSpecification<TCustomer>)
    function IsSatisfiedBy(const C: TCustomer): Boolean; override;
  end;

  TSalaryAbove = class(TSpecification<TCustomer>)
    function IsSatisfiedBy(const C: TCustomer): Boolean; override;
  end;
```

Usage:

```pascal
var spec := TDepartmentIs.Create('IT')
              .AndAlso(TSalaryAbove.Create(70000));

for c in fCustomers do
  if spec.IsSatisfiedBy(c) then
    ShowMessage(c.Name);
```

### Scope

A simple way to avoid try/finally/free blocks in your code.

#### Examples

This example from **Tests.Core** demonstrates four instances of the class TLanguage being cleaned up automatically. TLanguage is regular class, it is not reference counted:

```pascal
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

## The  Okay(ish)

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

Delphi just isn't designed as a first class functional language, the fact that you can actually implement fully functional monads is a testament to its power and flexibility. It really shines when used as intended. Fully functional constructs become such an exercise in beat the compiler, and verbosity, that they offer very little benefit.

This is an example of using **Zip** function:

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

There's so much syntax noise, for such a simple function, it's unnecessarily complex.

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

The **Tests.Result.Complex.pas** file contains a number of unit tests demonstrating a number of the functions.

The **TResult** tests were split into two, to highlight the distinction in complexity. **SharedKernel.Core.pas** will similarly have the more complex functions split out to a helper unit.

## The Project

The project is a **DUnitX** test project. 

There are four core files:

- SharedKernel.Container.pas   
- SharedKernel.Core.pas          
- SharedKernel.Specifications.pas
- SharedKernel.Streams.pas

The rest of the code is in a dozen tests and a couple of simple mock objects.    

I have defined **TESTINSIGHT** in the **.dpr**:

```pascal
{$DEFINE TESTINSIGHT}
```

There's an overview of **TestInsight** [here](https://delphisorcery.blogspot.com/2021/04/testinsight-12-released.html) from where you can download and install it - highly recommended, it is excellent. Once **TestInisight** is installed, you can run or debug the tests as per normal.

![image-20250613202917759](https://github.com/user-attachments/assets/8d0236e3-e62d-4bde-9870-914ce655cff3)

## What Next

This was an interesting project, I learned a lot. Some things turned out better than expected, such as the **Stream** type. That's one type I'll be improving and adopting in projects moving forwards.

Attempting to build such abstractions in Delphi is a good exercise for Developers seeking a deeper understanding of the RTTI and Generics. I remember struggling trying to use generics to solve a problem, and nothing would work. Event **array of const** and **Variants** were of no use - onr can't accept enum and interface arguments, the second loses interface type information. Success came when I stopped trying to fight the compiler, and to think differently.

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

