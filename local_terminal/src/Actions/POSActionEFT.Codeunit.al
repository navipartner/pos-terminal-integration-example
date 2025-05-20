codeunit 50100 "PTE POS Action - EFT" implements "NPR POS IPaymentWFHandler", "NPR IPOS Workflow"
{
    procedure GetPaymentHandler(): Code[20]
    begin
        exit(Format(Enum::"NPR POS Workflow"::PTE_POS_ACTION_EFT));
    end;

    procedure Register(WorkflowConfig: codeunit "NPR POS Workflow Config")
    begin
        WorkflowConfig.AddJavascript(GetActionScript());
        WorkflowConfig.AddLabel('title', 'Payment');
        WorkflowConfig.AddLabel('status', 'Waiting For Terminal...');
        WorkflowConfig.AddActionDescription('A custom example integration to a local terminal via the hardware connector');
    end;

    procedure RunWorkflow(Step: Text; Context: codeunit "NPR POS JSON Helper"; FrontEnd: codeunit "NPR POS Front End Management"; Sale: codeunit "NPR POS Sale"; SaleLine: codeunit "NPR POS Sale Line"; PaymentLine: codeunit "NPR POS Payment Line"; Setup: codeunit "NPR POS Setup")
    begin
        case Step of
            'StartTransaction':
                begin
                    FrontEnd.WorkflowResponse(CreateRequest(Context));
                end;
            'HandleResponse':
                begin
                    FrontEnd.WorkflowResponse(ParseResponse(Context));
                end;
        end;
    end;

    local procedure CreateRequest(Context: Codeunit "NPR POS JSON Helper"): JsonObject
    var
        TerminalRequest: Record "PTE Terminal Request";
        POSSale: Codeunit "NPR POS Sale";
        POSSaleRecord: Record "NPR POS Sale";
        GLSetup: Record "General Ledger Setup";
        POSSession: Codeunit "NPR POS Session";
        hwcRequest: JsonObject;
        Json: JsonObject;
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

        Commit(); // leave a trace of the request in BC table in case anything fails later. Some terminals support doing lookup of crashed transactions via id.

        hwcRequest.Add('Type', 'Transaction');
        hwcRequest.Add('TransactionId', Format(TerminalRequest."Transaction ID", 0, 9));
        hwcRequest.Add('Amount', TerminalRequest.Amount);
        hwcRequest.Add('Currency', TerminalRequest."Currency Code");
        hwcRequest.Add('TerminalIP', '192.168.1.100'); // TODO: get this and other required fields from a setup table in BC, connected to each POS unit.

        Json.Add('hwcRequest', hwcRequest);
        Json.Add('formattedAmount', Format(TerminalRequest.Amount, 0, '<Precision,2:2><Standard Format,2>'));
        Json.Add('transactionId', Format(TerminalRequest."Transaction ID", 0, 9));
        exit(Json);
    end;

    local procedure ParseResponse(Context: Codeunit "NPR POS JSON Helper"): JsonObject
    var
        TerminalResponseParser: Codeunit "PTE Terminal Response Parser";
        TerminalResponse: Record "PTE Terminal Response";
        TerminalReceipt: Record "PTE Terminal Receipt";
        ParsingErr: Label 'Error while parsing terminal response:\%1';
        PrintingErr: Label 'Error while printing terminal receipt:\%1';
        Json: JsonObject;
        TransactionId: Guid;
        StringTransactionId: Text;
        hwcResponse: JsonObject;
    begin
        Context.GetJObject(hwcResponse);
        Context.GetString('Id', StringTransactionId);
        Evaluate(TransactionId, StringTransactionId);

        TerminalResponseParser.SetResponse(format(hwcResponse));
        if TerminalResponseParser.Run() then begin
            // Implicit commit after codeunit.run succeeded - Terminal response and POS lines are now in the sale if parsing succeeded.
            TerminalReceipt.SetRange("Transaction ID", TransactionId);
            if not Codeunit.Run(Codeunit::"PTE Terminal Receipt", TerminalReceipt) then begin
                Message(PrintingErr, GetLastErrorText());
            end;

            TerminalResponse.SetRange("Transaction ID", TransactionId);
            TerminalResponse.FindLast();
            Json.Add('success', TerminalResponse.Approved);

            if (not TerminalResponse.Approved) then begin
                Message(TerminalResponse."PSP Error Code");
            end;
        end else begin
            Message(ParsingErr, GetLastErrorText());
            Json.Add('success', false);
        end;

        Json.Add('done', true);
        exit(Json);
    end;

    local procedure GetActionScript(): Text
    begin
        exit(
            //###NPR_INJECT_FROM_FILE:POSActionEFT.Codeunit.js###
            'const main=async({workflow:i,context:a,popup:u,captions:o,hwc:e})=>{debugger;const n=await i.respond("StartTransaction");let s;const t=await u.simplePayment({title:o.title,initialStatus:o.status,showStatus:!0,amount:n.formattedAmount,onAbort:async()=>{await e.invoke("DemoTerminal",{Type:"Abort",TransactionId:n.transactionId},s)}});try{s=e.registerResponseHandler(async r=>{switch(r.Type){case"Transaction":{const c=await i.respond("HandleResponse",r);c.done&&(a.success=c.success,e.unregisterResponseHandler(s))}break;case"UIUpdate":t.updateStatus(r.UIMessage);break}}),await e.invoke("DemoTerminal",n.hwcRequest,s),t.enableAbort(!0),await e.waitForContextCloseAsync(s)}finally{t&&t.close()}return{success:a.success,tryEndSale:a.success}};'
        );
    end;
}