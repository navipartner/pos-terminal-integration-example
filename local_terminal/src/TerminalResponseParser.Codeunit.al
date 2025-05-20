codeunit 50103 "PTE Terminal Response Parser"
{
    var
        _JsonResponse: Text;

    trigger OnRun()
    begin
        ParseResponse(_JsonResponse);
    end;

    procedure SetResponse(ResponseIn: Text)
    begin
        _JsonResponse := ResponseIn;
    end;

    local procedure ParseResponse(Json: Text)
    var
        TerminalResponse: Record "PTE Terminal Response";
        TerminalReceipt: Record "PTE Terminal Receipt";
        LineNo: Integer;
        POSActionEFT: Codeunit "PTE POS Action - EFT";
        POSSession: Codeunit "NPR POS Session";
        POSPaymentLine: Codeunit "NPR POS Payment Line";
        POSLine: Record "NPR POS Sale Line";
        TerminalRequest: Record "PTE Terminal Request";
        EFTCardDetection: Codeunit "NPR EFT Card Detection";
        POSPaymentMethod: Record "NPR POS Payment Method";
    begin
        ParseTerminalResponse(TerminalRequest, TerminalResponse);

        //Detect payment method mapping to card type
        if not EFTCardDetection.DetectApplicationID(TerminalResponse."Card Application ID", POSPaymentMethod, TerminalRequest."POS Sale Location Code") then
            if not EFTCardDetection.DetectBIN(TerminalResponse."Card Number", POSPaymentMethod, TerminalRequest."POS Sale Location Code") then
                POSPaymentMethod.Get(TerminalResponse."Original POS Payment Method");
        TerminalResponse."POS Payment Method" := POSPaymentMethod.Code;

        //Create POS Payment Line
        POSSession.GetPaymentLine(POSPaymentLine);
        POSPaymentLine.GetPaymentLine(POSLine);

        POSLine."No." := TerminalResponse."POS Payment Method";
        POSLine."EFT Approved" := TerminalResponse.Approved;
        POSLine.Description := CopyStr(POSPaymentMethod.Description, 1, MaxStrLen(POSLine.Description));
        POSLine.Reference := CopyStr(TerminalResponse."PSP Reference No.", 1, MaxStrLen(POSLine.Reference));
        if POSLine."EFT Approved" then begin
            POSLine."Amount Including VAT" := TerminalResponse."Approved Amount";
            POSLine."Currency Amount" := POSLine."Amount Including VAT";
        end;
        POSPaymentLine.InsertPaymentLine(POSLine, 0);
        POSPaymentLine.GetCurrentPaymentLine(POSLine);

        // Store the POS line systemId in EFT table so we can see later if sale completed as it should (the systemIds remain intact when moved 
        // to POS Entry header and lines for completed sales)
        TerminalResponse."POS Payment Line No." := POSLine."Line No.";
        TerminalResponse."POS Payment Line ID" := POSLine.SystemId;
        TerminalResponse.Modify();
    end;

    local procedure ParseTerminalResponse(var TerminalRequest: Record "PTE Terminal Request"; var TerminalResponse: Record "PTE Terminal Response")
    var
        CurrencyCode: Text;
        TransactionId: Text;
        ReceiptLines: List of [Text];
        Line: Text;
        LineNo: Integer;
        TerminalReceipt: Record "PTE Terminal Receipt";
        JsonParser: Codeunit "NPR Json Parser";
    begin
        TerminalResponse.Init();
        JsonParser
            .Parse(_JsonResponse)
                .GetProperty('Id', TransactionId)
                .GetProperty('PSPReference', TerminalResponse."PSP Reference No.")
                .GetProperty('PSPErrorCode', TerminalResponse."PSP Error Code")
                .GetProperty('MaskedCardNumber', TerminalResponse."Card Number")
                .GetProperty('ApprovedAmount', TerminalResponse."Approved Amount")
                .GetProperty('Success', TerminalResponse.Approved)
                .GetProperty('CardType', TerminalResponse."Card Type")
                .GetProperty('Currency', CurrencyCode)
                .GetProperty('ReceiptLines', ReceiptLines)
                .GetProperty('ApplicationId', TerminalResponse."Card Application ID");
        TerminalResponse."Transaction ID" := TransactionId;
        TerminalResponse."Currency Code" := CurrencyCode;

        TerminalRequest.SetRange("Transaction ID", TransactionId);
        TerminalRequest.FindFirst();

        TerminalResponse."Original POS Payment Method" := TerminalRequest."POS Payment Method";
        TerminalResponse.Insert();

        foreach Line in ReceiptLines do begin
            LineNo += 1;
            TerminalReceipt.Init();
            TerminalReceipt."Entry No." := 0;
            TerminalReceipt."Transaction ID" := TerminalResponse."Transaction ID";
            TerminalReceipt."Line No." := LineNo;
            TerminalReceipt."Receipt Line Value" := Line;
            TerminalReceipt.Insert();
        end;
    end;
}