codeunit 50100 "PTE POS Action - EFT" implements "NPR POS IPaymentWFHandler", "NPR IPOS Workflow"
{
    SingleInstance = true;

    var
        _response: Dictionary of [Text, Text];

    procedure GetPaymentHandler(): Code[20]
    begin
        exit(Format(Enum::"NPR POS Workflow"::PTE_POS_ACTION_EFT));
    end;

    procedure Register(WorkflowConfig: codeunit "NPR POS Workflow Config")
    begin
        WorkflowConfig.AddJavascript(GetActionScript());
        WorkflowConfig.AddLabel('title', 'Payment');
        WorkflowConfig.AddLabel('status', 'Waiting For Terminal...');
        WorkflowConfig.AddActionDescription('A custom example integration to a cloud terminal API');
    end;

    procedure RunWorkflow(Step: Text; Context: codeunit "NPR POS JSON Helper"; FrontEnd: codeunit "NPR POS Front End Management"; Sale: codeunit "NPR POS Sale"; SaleLine: codeunit "NPR POS Sale Line"; PaymentLine: codeunit "NPR POS Payment Line"; Setup: codeunit "NPR POS Setup")
    var
        transactionId: Text;
    begin
        case Step of
            'StartTransaction':
                begin
                    // Create request record with unique ID and commit it before sending it off.
                    // Start background task that will fire off the request.
                    // Return the unique ID to the frontend so it can poll the backend using it.
                    FrontEnd.WorkflowResponse(CreateAndSendRequest(Context));
                end;
            'PollResponse':
                begin
                    // Check the global dictionary to see if we have a response for our request yet.
                    // If we have, then parse it into a response record, create a payment line in the POS for the
                    // approved amount and commit + print terminal receipt

                    transactionId := Context.GetString('transactionId');
                    if not _response.ContainsKey(transactionId) then
                        exit;

                    FrontEnd.WorkflowResponse(ParseResponse(_response.Get(transactionId), transactionId));
                end;
            'RequestAbort':
                begin
                    // Fire abort request towards the external API - in this example we expect the external API to handle
                    // returning a nice response to us, like any other payment response, with status cancelled.
                    FrontEnd.WorkflowResponse(RequestAbortPayment(Context));
                end;
        end;
    end;

    local procedure CreateAndSendRequest(Context: Codeunit "NPR POS JSON Helper") Json: JsonObject
    var
        TerminalRequest: Record "PTE Terminal Request";
        POSSession: Codeunit "NPR POS Session";
        POSSale: Codeunit "NPR POS Sale";
        POSSaleRecord: Record "NPR POS Sale";
        GLSetup: Record "General Ledger Setup";
        POSBackgroundTaskAPI: Codeunit "NPR POS Background Task API";
        TaskId: Integer;
        Parameters: Dictionary of [Text, Text];
    begin
        POSSession.GetSale(POSSale);
        POSSale.GetCurrentSale(POSSaleRecord);

        GLSetup.FindFirst();

        TerminalRequest.Init();
        TerminalRequest."Transaction ID" := CreateGuid();
        TerminalRequest."Request Time" := CurrentDateTime();
        TerminalRequest."POS Unit No." := POSSaleRecord."Register No.";
        TerminalRequest."Salesperson Code" := POSSaleRecord."Salesperson Code";
        TerminalRequest."POS Receipt No." := POSSaleRecord."Sales Ticket No.";
        TerminalRequest."POS Sale Id" := POSSaleRecord.SystemId;
        TerminalRequest."Request Type" := Enum::"PTE Terminal Request Type"::Payment; //TODO: implement refund and more.
        TerminalRequest.Amount := Context.GetDecimal('suggestedAmount');
        TerminalRequest."Currency Code" := GLSetup."LCY Code";
        TerminalRequest."POS Payment Method" := Context.GetString('paymentType');
        TerminalRequest."POS Sale Location Code" := POSSaleRecord."Location Code";
        TerminalRequest.Insert();

        Commit(); // leave a trace of the request in case anything fails later.

        POSSession.GetPOSBackgroundTaskAPI(POSBackgroundTaskAPI);
        Parameters.Add('requestEntryNo', Format(TerminalRequest."Entry No."));
        POSBackgroundTaskAPI.EnqueuePOSBackgroundTask(TaskId, Enum::"NPR POS Background Task"::"PTE Terminal Payment Request", Parameters, 1000 * 60 * 5);

        Json.Add('formattedAmount', Format(TerminalRequest.Amount, 0, '<Precision,2:2><Standard Format,2>'));
        Json.Add('transactionId', Format(TerminalRequest."Transaction ID", 0, 9));
    end;

    local procedure ParseResponse(Response: Text; transactionId: Text) Json: JsonObject
    var
        TerminalResponseParser: Codeunit "PTE Terminal Response Parser";
        TerminalResponse: Record "PTE Terminal Response";
        TerminalReceipt: Record "PTE Terminal Receipt";
        ParsingErr: Label 'Error while parsing terminal response:\%1';
        PrintingErr: Label 'Error while printing terminal receipt:\%1';
    begin
        TerminalResponseParser.SetResponse(Response);
        if TerminalResponseParser.Run() then begin
            // Implicit commit after codeunit.run succeeded - Terminal response and POS lines are now in the sale if parsing succeeded.
            TerminalReceipt.SetRange("Transaction ID", transactionId);
            if not Codeunit.Run(Codeunit::"PTE Terminal Receipt", TerminalReceipt) then begin
                Message(PrintingErr, GetLastErrorText());
            end;

            TerminalResponse.SetRange("Transaction ID", transactionId);
            TerminalResponse.FindLast();
            Json.Add('success', TerminalResponse.Approved);

            if (not TerminalResponse.Approved) then begin
                Message(TerminalResponse."PSP Error Code");
            end;

        end else begin
            Message(ParsingErr, GetLastErrorText());
            Json.Add('success', false);
            // TODO: Implement parsing error handling with lookup action that can be used if anything fails. And log to telemetry so developer can fix bug ASAP.
        end;

        _response.Remove(transactionId);

        Json.Add('done', true);
    end;

    local procedure RequestAbortPayment(Context: Codeunit "NPR POS JSON Helper"): JsonObject
    var
        POSBackgroundTaskAPI: Codeunit "NPR POS Background Task API";
        POSSession: Codeunit "NPR POS Session";
    begin
        POSSession.GetPOSBackgroundTaskAPI(POSBackgroundTaskAPI);

        // TODO: Implement abort request:
        //POSBackgroundTaskAPI.EnqueuePOSBackgroundTask(TaskId, Enum::"NPR POS Background Task"::"PTE Terminal Abort Request", Parameters, 1000 * 10);
    end;

    procedure SetResponse(transactionId: Text; JsonResponse: Text)
    begin
        _response.Set(TransactionId, JsonResponse);
    end;

    local procedure GetActionScript(): Text
    begin
        exit(
            //###NPR_INJECT_FROM_FILE:POSActionEFT.Codeunit.js###
            'const main=async({workflow:e,context:t,popup:o,captions:n})=>{let r=await e.respond("StartTransaction");t.formattedAmount=r.formattedAmount,t.transactionId=r.transactionId;let a=await o.simplePayment({title:n.title,initialStatus:n.status,showStatus:!0,amount:t.formattedAmount,onAbort:async()=>{await e.respond("RequestAbort")}}),u=new Promise((c,l)=>{let i=async()=>{try{let s=await e.respond("PollResponse");if(s.done){t.success=s.success,c();return}}catch(s){try{await e.respond("RequestAbort")}catch{}l(s);return}setTimeout(i,1e3)};setTimeout(i,1e3)});try{a.enableAbort(!0),await u}finally{a&&a.close()}return{success:t.success,tryEndSale:t.success}};'
        );
    end;
}