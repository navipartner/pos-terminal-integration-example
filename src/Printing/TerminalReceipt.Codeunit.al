codeunit 50101 "PTE Terminal Receipt"
{
    TableNo = "PTE Terminal Receipt";

    trigger OnRun()
    var
        PrinterDeviceSettings: Record "NPR Printer Device Settings" temporary;
        Printer: Codeunit "NPR RP Line Print";
        TerminalReceipt: Record "PTE Terminal Receipt";
    begin
        TerminalReceipt.CopyFilters(Rec);
        if not TerminalReceipt.FindSet() then
            exit;

        Printer.SetAutoLineBreak(true);
        Printer.SetTwoColumnDistribution(0.5, 0.5);
        Printer.SetPadChar('');
        Printer.SetBold(false);
        Printer.SetFont('A11');

        repeat
            Printer.AddLine(TerminalReceipt."Receipt Line Value", 0);
        until TerminalReceipt.Next() = 0;

        Printer.SetFont('COMMAND');
        Printer.AddLine('PAPERCUT', 0);

        Printer.ProcessBuffer(Codeunit::"PTE Terminal Receipt", Enum::"NPR Line Printer Device"::Epson, PrinterDeviceSettings);
    end;
}