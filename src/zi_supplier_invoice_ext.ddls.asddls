@AbapCatalog.sqlViewAppendName: 'ZISUPPINVEXT'
@EndUserText.label: 'Supplier Invoice API Extension for Payee'
extend view I_SupplierInvoice with ZI_SUPPLIER_INVOICE_EXT {
    rbkp.empfb as Payee
}
