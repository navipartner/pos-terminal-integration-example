enumextension 50101 "PTE POS Actions" extends "NPR POS Workflow"
{
    value(50100; PTE_POS_ACTION_EFT)
    {
        Caption = 'PTE_POS_ACTION_EFT', Locked = true, MaxLength = 20;
        Implementation = "NPR IPOS Workflow" = "PTE POS Action - EFT";
    }
}