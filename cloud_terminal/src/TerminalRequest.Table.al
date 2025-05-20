table 50100 "PTE Terminal Request"
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
        field(3; "Request Time"; DateTime)
        { }
        field(4; "POS Unit No."; Code[20])
        { }
        field(5; "Salesperson Code"; Code[20])
        { }
        field(6; "POS Receipt No."; Code[20])
        { }
        field(7; "POS Sale Id"; Guid)
        { }
        field(8; "Request Type"; Enum "PTE Terminal Request Type")
        { }
        field(9; "Amount"; Decimal)
        { }
        field(10; "Currency Code"; Code[10])
        { }
        field(11; "POS Payment Method"; Code[10])
        { }
        field(12; "POS Sale Location Code"; Code[20])
        { }
        field(13; "Response Exists"; Boolean)
        {
            CalcFormula = exist("PTE Terminal Response" where("Transaction ID" = field("Transaction ID")));
            FieldClass = FlowField;
        }
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