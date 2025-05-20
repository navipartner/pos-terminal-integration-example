enumextension 50100 "PTE EFT Payment Processing" extends "NPR Payment Processing Type"
{
    value(50100; "PTE EFT")
    {
        Caption = 'Custom Terminal Integration';
        Implementation = "NPR POS IPaymentWFHandler" = "PTE POS Action - EFT";
    }
}