const main = async ({ workflow, context, popup, captions, hwc }) => {
  debugger;
  const startTrxResponse = await workflow.respond("StartTransaction");
  let _contextId;

  const _dialogRef = await popup.simplePayment({
    title: captions.title,
    initialStatus: captions.status,
    showStatus: true,
    amount: startTrxResponse.formattedAmount,
    onAbort: async () => {
      await hwc.invoke(
        "DemoTerminal",
        {
          Type: "Abort",
          TransactionId: startTrxResponse.transactionId,
        },
        _contextId
      );
    },
  });
  try {
    _contextId = hwc.registerResponseHandler(async (hwcResponse) => {
      // Handle responses from HWC here
      switch (hwcResponse.Type) {
        case "Transaction":
          {
            const BCParsedResponse = await workflow.respond(
              "HandleResponse",
              hwcResponse
            );
            if (BCParsedResponse.done) {
              context.success = BCParsedResponse.success;
              hwc.unregisterResponseHandler(_contextId);
            }
          }
          break;
        case "UIUpdate":
          _dialogRef.updateStatus(hwcResponse.UIMessage);
          break;
      }
    });

    await hwc.invoke("DemoTerminal", startTrxResponse.hwcRequest, _contextId); // start transaction on terminal

    _dialogRef.enableAbort(true);
    await hwc.waitForContextCloseAsync(_contextId); // waits for transaction to finish via hwc response handler
  } finally {
    if (_dialogRef) {
      _dialogRef.close();
    }
  }

  return { success: context.success, tryEndSale: context.success };
};
