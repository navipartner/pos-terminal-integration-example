# POS Terminal Integration Example
This repo contains an example of how to integrate a POS Terminal into NaviPartners POS Solution from a Per-Tenant Extension.  
The example assumes that your terminal has a cloud API like most modern terminals do.

## Prerequisites
You should install [our VSCode extension](https://marketplace.visualstudio.com/items?itemName=NaviPartner.np-retail-workflow-language-support) along with [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode).  
It will give you intellisense on parameters in your action javascript files, automatically maintain the minified codeunit string when you make changes to the javascript and enforce your javascript style.

## Example Components

- A workflow codeunit & javascript combo that implements the frontend (javascript) and backend (AL) sides of the integration.
- A custom payment method enum extension which is the type you will select on your POS Payment method.
- Usage of our "POS Background Task" library which allows you to run page background tasks inside the big POS page.
  This is how we make long-living HTTP requests to a cloud terminal API without blocking further AL execution completely for minutes!
- A polling mechanism from frontend to backend that check when our long-living HTTP request is done.
- An abort mechanism so the salesperson can abort payment.
- A simple request & response terminal with the most basic fields.
- A simple receipt print example table + codeunit layout.
- Mapping on Card Application ID or BIN (first 6 digits of the card number) to a POS Payment Method to post payments on card specific accounts.

## Example Behavior

This example will auto approve any amount, except 666, after 5 seconds sleep to mimic making a real HTTP request.   
If you attempt to pay amount 666 it will fail with wrong PIN as reason.

## Setup

- Create a POS Payment method with type "Custom Terminal Integration" and make a POS Button in the editor which uses your new POS Payment method.
- Page "Report Selection - Retail" -> "Terminal Receipt" -> Create line with the "PTE Terminal Receipt" codeunit ID.
- Page "Print Template Output Setup" -> Create line for the "PTE Terminal Receipt" codeunit with "Output Type" and "Output Path" set according to your printer specifications. For an epson receipt printer created in windows with driver "Generic/Text Only", setup "Output Type"="Printer Name" and "Output Path"=Your_printer_name.
- Page "EFT Mapping" -> Create as many card specific groups and fill either Application ID or BIN ranges to map from generic "Terminal" POS Payment Method to card specific POS Payment Method. This allows you control over G/L accounts and captions for print.

## Limitations

This example does not contain full implementations of abort, refunds, voids, lookups, tips, surcharge or other special operations but it can be extended to support all of those, based on the same scaffolding and architecture. TODOs are left in the code for some of these.
