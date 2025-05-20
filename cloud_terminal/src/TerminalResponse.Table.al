table 50101 "PTE Terminal Response"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Transaction ID"; Guid)
        { }
        field(3; "Approved Amount"; Decimal)
        { }
        field(4; "Card Type"; Text[50])
        { }
        field(5; "Card Number"; Text[50])
        { }
        field(6; "PSP Reference No."; Text[50])
        { }
        field(7; "PSP Error Code"; Text[50])
        { }
        field(8; Approved; Boolean)
        { }
        field(9; "Currency Code"; Code[10])
        { }
        field(10; "POS Payment Line No."; Integer)
        { }
        field(11; "POS Payment Line Id"; Guid)
        { }
        field(12; "POS Payment Method"; Code[10])
        { }
        field(13; "Original POS Payment Method"; Code[10])
        { }
        field(14; "Card Application ID"; Text[50])
        { }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction ID")
        { }
    }
}