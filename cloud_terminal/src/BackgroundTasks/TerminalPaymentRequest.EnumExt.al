enumextension 50102 "PTE Terminal Payment Request" extends "NPR POS Background Task"
{
    value(50100; "PTE Terminal Payment Request")
    {
        Caption = 'PTE_TERMINAL_PAYMENT_REQUEST', Locked = true;
        Implementation = "NPR POS Background Task" = "PTE Payment Request Task";
    }
}