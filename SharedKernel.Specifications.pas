unit SharedKernel.Specifications;

interface

uses
  System.SysUtils,
  SharedKernel.Core;

type
  ISpecification<T> = interface
    ['{E516E6C7-2E3A-4F16-94DE-F041C3E125B9}']
    function IsSatisfiedBy(const Candidate: T): Boolean;
  end;

  ISpecificationEx<T> = interface(ISpecification<T>)
    function AndAlso(const Other: ISpecification<T>): ISpecification<T>;
    function OrElse(const Other: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;
  end;

  TSpecification<T> = class(TInterfacedObject, ISpecification<T>, ISpecificationEx<T>)
  public
    function IsSatisfiedBy(const Candidate: T): Boolean; virtual; abstract;

    function AndAlso(const Other: ISpecification<T>): ISpecification<T>;
    function OrElse(const Other: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;
  end;

  TAndSpecification<T> = class(TSpecification<T>)
  private
    FLeft, FRight: ISpecification<T>;
  public
    constructor Create(const Left, Right: ISpecification<T>);
    function IsSatisfiedBy(const Candidate: T): Boolean; override;
  end;

  TOrSpecification<T> = class(TSpecification<T>)
  private
    FLeft, FRight: ISpecification<T>;
  public
    constructor Create(const Left, Right: ISpecification<T>);
    function IsSatisfiedBy(const Candidate: T): Boolean; override;
  end;

  TNotSpecification<T> = class(TSpecification<T>)
  private
    FInner: ISpecification<T>;
  public
    constructor Create(const Inner: ISpecification<T>);
    function IsSatisfiedBy(const Candidate: T): Boolean; override;
  end;

implementation

{ TSpecification<T> }

function TSpecification<T>.AndAlso(const Other: ISpecification<T>): ISpecification<T>;
begin
  Result := TAndSpecification<T>.Create(Self, Other);
end;

function TSpecification<T>.OrElse(const Other: ISpecification<T>): ISpecification<T>;
begin
  Result := TOrSpecification<T>.Create(Self, Other);
end;

function TSpecification<T>.NotThis: ISpecification<T>;
begin
  Result := TNotSpecification<T>.Create(Self);
end;

{ TAndSpecification<T> }

constructor TAndSpecification<T>.Create(const Left, Right: ISpecification<T>);
begin
  inherited Create;
  FLeft := Left;
  FRight := Right;
end;

function TAndSpecification<T>.IsSatisfiedBy(const Candidate: T): Boolean;
begin
  Result := FLeft.IsSatisfiedBy(Candidate) and FRight.IsSatisfiedBy(Candidate);
end;

{ TOrSpecification<T> }

constructor TOrSpecification<T>.Create(const Left, Right: ISpecification<T>);
begin
  inherited Create;
  FLeft := Left;
  FRight := Right;
end;

function TOrSpecification<T>.IsSatisfiedBy(const Candidate: T): Boolean;
begin
  Result := FLeft.IsSatisfiedBy(Candidate) or FRight.IsSatisfiedBy(Candidate);
end;

{ TNotSpecification<T> }

constructor TNotSpecification<T>.Create(const Inner: ISpecification<T>);
begin
  inherited Create;
  FInner := Inner;
end;

function TNotSpecification<T>.IsSatisfiedBy(const Candidate: T): Boolean;
begin
  Result := not FInner.IsSatisfiedBy(Candidate);
end;

end.
