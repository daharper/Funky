unit Mocks.Services;

interface

uses
  System.Generics.Collections,
  SharedKernel.Core,
  SharedKernel.Streams,
  Mocks.Entities,
  Mocks.Repositories;

type
  ISaleService = interface
    ['{12BBF70F-664F-4BB7-9266-1CDCF9B0E2D2}']

    function Id: integer;
    function Count: integer;
    function Stream: Stream<TSale>;
    function GetEnumerator: TEnumerator<TSale>;
  end;

  TSaleService = class(TTransient, ISaleService)
  private
    fSales: TSalesList;

    class var
      fId: integer;

  public
    function Id: integer;
    function Count: integer;
    function Stream: Stream<TSale>;
    function GetEnumerator: TEnumerator<TSale>;

    constructor Create(aGrocerySales: ISaleRepository; aCarSales: ICarSaleRepository);
    destructor Destroy; override;
  end;

implementation

{ SaleService }

{----------------------------------------------------------------------------------------------------------------------}
function TSaleService.Count: integer;
begin
  Result := fSales.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSaleService.Create(aGrocerySales: ISaleRepository; aCarSales: ICarSaleRepository);
begin
  Inc(fId);

  fSales := aGrocerySales.Stream.Concat(aCarSales.Stream).ToList;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSaleService.Destroy;
begin
  fSales.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleService.GetEnumerator:TEnumerator<TSale>;
begin
  Result := fSales.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleService.Stream: Stream<TSale>;
begin
  Result.InitializeFrom(fSales);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleService.Id: integer;
begin
  Result := fId;
end;

end.
