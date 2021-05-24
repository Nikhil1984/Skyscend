@AbapCatalog.sqlViewAppendName: 'ZASUPPLINVEXT'
@EndUserText.label: 'Supplier Invoice API Extension'
extend view A_SupplierInvoice with ZASUPPLIER_INVOICE_EXT {
    Payee,
    ReverseDocument,
    ReverseDocumentFiscalYear
}
