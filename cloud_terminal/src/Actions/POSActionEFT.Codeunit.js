const main = async ({ workflow, context, popup, captions }) => {
  let startTrxResponse = await workflow.respond("StartTransaction");
  context.formattedAmount = startTrxResponse.formattedAmount;
  context.transactionId = startTrxResponse.transactionId;

  let _dialogRef = await popup.simplePayment({
    title: captions.title,
    initialStatus: captions.status,
    showStatus: true,
    amount: context.formattedAmount,
    onAbort: async () => {
      await workflow.respond("RequestAbort");
    },
  });

  let trxPromise = new Promise((resolve, reject) => {
    let pollFunction = async () => {
      try {
        let pollResponse = await workflow.respond("PollResponse");
        if (pollResponse.done) {
          context.success = pollResponse.success;
          resolve();
          return;
        }
      } catch (exception) {
        try {
          await workflow.respond("RequestAbort");
        } catch {}
        reject(exception);
        return;
      }
      setTimeout(pollFunction, 1000);
    };
    setTimeout(pollFunction, 1000);
  });

  try {
    _dialogRef.enableAbort(true);
    await trxPromise;
  } finally {
    if (_dialogRef) {
      _dialogRef.close();
    }
  }

  return { success: context.success, tryEndSale: context.success };
};
