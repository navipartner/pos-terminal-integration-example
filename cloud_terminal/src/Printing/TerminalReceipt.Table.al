table 50102 "PTE Terminal Receipt"
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
        field(3; "Line No."; Integer)
        { }
        field(10; "Receipt Line Value"; Text[50])
        { }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction ID", "Line No.")
        { }
    }
}