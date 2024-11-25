codeunit 50102 "PTE Payment Request Task" implements "NPR POS Background Task"
{
    procedure ExecuteBackgroundTask(TaskId: Integer; Parameters: Dictionary of [Text, Text]; var Result: Dictionary of [Text, Text])
    var
        RequestJson: Codeunit "NPR Json Builder";
        ResponseJson: Codeunit "NPR Json Builder";
        TerminalRequest: Record "PTE Terminal Request";
        Success: Boolean;
        RequestEntryNo: Integer;
        Json: Text;
    begin
        // We simulate building a small json request from the request record,
        // sending a http request (5 seconds sleep instead) while waiting for customer to tap his card and PIN,
        // and then we build the response JSON which we would get back from API, to be parsed later.

        Evaluate(RequestEntryNo, Parameters.Get('requestEntryNo'));
        TerminalRequest.Get(RequestEntryNo);

        RequestJson
            .StartObject()
                .AddProperty('id', TerminalRequest."Transaction ID")
                .AddProperty('amount', TerminalRequest."Amount")
                .AddProperty('currency', TerminalRequest."Currency Code")
            .EndObject();

        Sleep(5000); // Simulate sending a http request to a terminal cloud API, waiting for customer to tap his card and PIN.

        Success := TerminalRequest.Amount <> 666;

        ResponseJson
            .StartObject()
                .AddProperty('id', TerminalRequest."Transaction ID")
                .AddProperty('pspReference', '1234567890')
                .AddProperty('cardType', 'Visa')
                .AddProperty('maskedCardNumber', '487145XXXXXX1234')
                .AddProperty('currency', TerminalRequest."Currency Code")
                .AddProperty('success', Success)
                .AddProperty('pspErrorCode', Success ? '' : 'WRONG_PIN')
                .AddProperty('approvedAmount', Success ? TerminalRequest."Amount" : 0)
                .AddProperty('applicationId', 'A0000001211010')
                .StartArray('receipt')
                    .AddValue('Terminal Receipt Line 1')
                    .AddValue('Terminal Receipt Line 2')
                    .AddValue('Terminal Receipt Line 3')
                    .AddValue(Success ? 'APPROVED' : 'FAILED - Incorrect PIN')
                .EndArray()
            .EndObject();

        ResponseJson.Build().WriteTo(Json);
        Result.Add('transactionId', TerminalRequest."Transaction ID");
        Result.Add('response', Json);
    end;

    procedure BackgroundTaskSuccessContinuation(TaskId: Integer; Parameters: Dictionary of [Text, Text]; Results: Dictionary of [Text, Text])
    var
        POSActionEFT: Codeunit "PTE POS Action - EFT";
    begin
        // Set response received back on the action and store the response payload in global variable
        // so it can be parsed on next poll in action
        POSActionEFT.SetResponse(Results.Get('transactionId'), Results.Get('response'));
    end;

    procedure BackgroundTaskErrorContinuation(TaskId: Integer; Parameters: Dictionary of [Text, Text]; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text)
    begin
        // TODO:
        // Log error to telemetry as it is critical timing.
        // Salesperson will need to do a lookup to recover potentially lost approval.
        // Log error into response table and write it on the screen to salesperson.

    end;

    procedure BackgroundTaskCancelled(TaskId: Integer; Parameters: Dictionary of [Text, Text])
    begin
        // TODO:
        // Log error to telemetry as it is critical timing.
        // Salesperson will need to do a lookup to recover potentially lost approval.
        // Log error into response table and write it on the screen to salesperson.
    end;
}