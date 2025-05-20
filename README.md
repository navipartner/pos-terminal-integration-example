# POS Terminal Integration Example
This repo contains two examples of how to integrate a POS Terminal into NaviPartners POS Solution from a Per-Tenant Extension.  
1) A cloud terminal integration that connects directly from BC to an online webservice API using HTTP requests. Many modern terminals support this.
2) A local terminal integration that connects from BC to a locally connected terminal (USB/Serial/LAN) via our hardware connector software installed locally on the POS machine.
Note: Local terminal integrations require a .dll plugin to be developed for our hardware connector. To see the example code for this, check repo https://github.com/navipartner/demoterminalplugin - the local_terminal app in this repo depends on that plugin being loaded in the hardware connector.

## Prerequisites
You should install [our VSCode extension](https://marketplace.visualstudio.com/items?itemName=NaviPartner.np-retail-workflow-language-support) along with [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode).  
It will give you intellisense on parameters in your action javascript files, automatically maintain the minified codeunit string when you make changes to the javascript and enforce your javascript style.

## Example Components

- A workflow codeunit & javascript combo that implements the frontend (javascript) and backend (AL) sides of the integration.
- A custom payment method enum extension which is the type you will select on your POS Payment method.
- (Cloud integration) Usage of our "POS Background Task" library which allows you to run page background tasks inside the big POS page.
  This is how we make long-living HTTP requests to a cloud terminal API without blocking further AL execution completely for minutes!
- (Cloud integration) A polling mechanism from frontend to backend that check when our long-living HTTP request is done.
- (Local integration) Ping pong between POS Action javascript and the local hardware connector software.
- An abort mechanism so the salesperson can abort payment.
- A simple request & response table with proper commit timing for the most basic fields.
- A simple receipt print example table + codeunit layout.
- Support for mapping cards via either Card Application ID or BIN (first 6 digits of the card number) to a POS Payment Method to post payments on card specific G/L accounts.

## Setup

- Create a POS Payment method with type "Custom Terminal Integration" and make a POS Button in the editor which uses your new POS Payment method.
- Page "Report Selection - Retail" -> "Terminal Receipt" -> Create line with the "PTE Terminal Receipt" codeunit ID.
- Page "Print Template Output Setup" -> Create line for the "PTE Terminal Receipt" codeunit with "Output Type" and "Output Path" set according to your printer specifications. For an epson receipt printer created in windows with driver "Generic/Text Only", setup "Output Type"="Printer Name" and "Output Path"=Your_printer_name.
- Page "EFT Mapping" -> Create as many card specific groups and fill either Application ID or BIN ranges to map from generic "Terminal" POS Payment Method to card specific POS Payment Method. This allows you control over G/L accounts and captions for print.

## Limitations

These examples do not contain full implementations of abort, refunds, voids, lookups, tips, surcharge or other special operations but it can be extended to support all of those, based on the same scaffolding and architecture.
