unit Tests.Stream;

interface

uses
  DUnitX.TestFramework,
  Mocks.Entities,
  Mocks.Repositories;

type
  [TestFixture]
  TStreamTests = class
    fCustomers: TCustomerRepository;

  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Create_Stream_ReturnsCorrectValues;
    [Test] procedure Reduce_Stream_ReturnsSingleValue;
    [Test] procedure Chaining_Methods_ReturnsCorrectValues;
    [Test] procedure Produce_Chars_GeneratesChars;
    [Test] procedure Count_Customers_In_IT_Deparment;
    [Test] procedure Should_Find_Min;
    [Test] procedure Should_Find_Max;
    [Test] procedure Should_Generate_Random_Numers;
    [Test] procedure Should_Give_the_Intersection;
    [Test] procedure Should_Give_the_Differences;
    [Test] procedure Should_Skip_While_Whitespace;
    [Test] procedure Should_Take_While_Not_Whitespace;
    [Test] procedure Should_Group_Employees_By_Department;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  System.Generics.Defaults,
  SharedKernel.Streams;

{ TStreamTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Count_Customers_In_IT_Deparment;
begin
  var i := fCustomers
      .Stream
      .Filter(function(c: TCustomer): boolean begin Result := c.Department = 'IT'; end)
      .Count;

  Assert.AreEqual(5, i);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Find_Max;
begin
  var max := Stream<integer>
      .From([2, 3, 1, 7, 4, 9, 5, 14, 6, 9, 8])
      .Max;

  Assert.AreEqual(14, max);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Find_Min;
begin
  var min := Stream<integer>
      .From([2, 3, 1, 7, 4, 9, 5, 14, 6, 9, 8])
      .Min;

  Assert.AreEqual(1, min);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Generate_Random_Numers;
begin
  var nums := Stream<integer>.Random(1, 6, 3).ToArray;

  Assert.AreEqual(3, Length(nums));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Give_the_Differences;
begin
  var other := Stream<string>.From(
      ['Ginny', 'Aidan', 'Shayndel', 'David', 'Ginny', 'Jaymin', 'Ginny']);

  var names := Stream<string>
      .From(['Rainen', 'Shayndel', 'Aidan', 'Jaymin'])
      .Difference<string>(other, function(c: string): string begin Result := c; end)
      .Sort
      .ToList;

  Assert.AreEqual(3, names.Count);

  Assert.AreEqual('David',  names[0]);
  Assert.AreEqual('Ginny',  names[1]);
  Assert.AreEqual('Rainen', names[2]);

  names.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Give_the_Intersection;
begin
  var other := Stream<string>.From(['Shayndel', 'Aidan']);

  var names := Stream<string>
      .From(['Rainen', 'Shayndel', 'Aidan', 'Jaymin'])
      .Intersect<string>(other, function(c: string): string begin Result := c; end)
      .Sort
      .ToList;

  Assert.AreEqual(2, names.Count);
  Assert.AreEqual('Aidan',    names[0]);
  Assert.AreEqual('Shayndel', names[1]);

  names.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Chaining_Methods_ReturnsCorrectValues;
begin
  var names := Stream<string>
      .From(['Rainen', 'Shayndel', 'Aidan', 'Jaymin', 'Mike'])
      .Concat(['David', 'Ginny', 'Shayndel', 'Aidan', 'Peter', 'Mary'])
      .Remove(Stream<string>.From(['Mike', 'Peter', 'Mary']))
      .Distinct
      .Sort(TIStringComparer.Ordinal)
      .Reverse
      .ToArray;

  Assert.AreEqual(6, Length(names));

  Assert.AreEqual('Shayndel', names[0]);
  Assert.AreEqual('Rainen',   names[1]);
  Assert.AreEqual('Jaymin',   names[2]);
  Assert.AreEqual('Ginny',    names[3]);
  Assert.AreEqual('David',    names[4]);
  Assert.AreEqual('Aidan',    names[5]);

end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Create_Stream_ReturnsCorrectValues;
begin
  var nums := Stream<Integer>.From([1, 2, 3, 4, 5]).ToArray;

  Assert.AreEqual(5, Length(nums));

  Assert.AreEqual(1, nums[0]);
  Assert.AreEqual(2, nums[1]);
  Assert.AreEqual(3, nums[2]);
  Assert.AreEqual(4, nums[3]);
  Assert.AreEqual(5, nums[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Produce_Chars_GeneratesChars;
begin
  var chars := Stream<char>.Produce('@', 10).ToArray;

  Assert.AreEqual(10, Length(chars));

  for var i := Low(chars) to High(chars) do
    Assert.AreEqual('@', chars[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Reduce_Stream_ReturnsSingleValue;
begin
  var stream := Stream<Integer>.From([1, 2, 3, 4, 5]);

  var sum := stream
      .Reduce<Integer>(0,
        function(acc, x: Integer): Integer
        begin
          Result := acc + x;
        end);

  Assert.AreEqual(15, sum);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Skip_While_Whitespace;
begin
  var text := Stream<char>
      .From('   hello'.ToCharArray)
      .SkipWhile(
        function(c: char): boolean
        begin
          Result := c.IsWhiteSpace;
        end)
      .Reduce<string>('',
        function(a: string; v: char): string
        begin
          Result := a + v;
        end);

  Assert.AreEqual('hello', text);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Take_While_Not_Whitespace;
begin
 var text := Stream<char>
      .From('hello world'.ToCharArray)
      .TakeWhile(function(c: char): boolean begin Result := not c.IsWhiteSpace; end)
      .Reduce<string>('', function(a: string; v: char): string begin Result := a + v; end);

  Assert.AreEqual('hello', text);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Should_Group_Employees_By_Department;
begin
  var depts := fCustomers
      .Stream
      .GroupBy(function(c: TCustomer): string begin Result := c.Department; end);

  Assert.AreEqual(5, depts['IT'].Count);
  Assert.AreEqual(1, depts['Management'].Count);
  Assert.AreEqual(1, depts['HR'].Count);
  Assert.AreEqual(2, depts['Testing'].Count);

  var it := Stream<TCustomer>
      .From(depts['it'])
      .Map<string>(function(c: TCustomer): string begin Result := c.Name; end)
      .ToList;

  Assert.IsTrue(it.Contains('Aidan'));
  Assert.IsTrue(it.Contains('Chris'));
  Assert.IsTrue(it.Contains('Slim'));
  Assert.IsTrue(it.Contains('Alan'));
  Assert.IsTrue(it.Contains('Roger'));

  var testing := Stream<TCustomer>
              .From(depts['testing'])
              .Map<string>(function(c: TCustomer): string begin Result := c.Name; end)
              .ToList;

  Assert.IsTrue(testing.Contains('Osin'));
  Assert.IsTrue(testing.Contains('Eduardo'));

  for var value in depts.Values do
    value.Free;

  it.Free;
  testing.Free;
  depts.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.Setup;
begin
  fCustomers := TCustomerRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamTests.TearDown;
begin
  fCustomers.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TStreamTests);

end.
