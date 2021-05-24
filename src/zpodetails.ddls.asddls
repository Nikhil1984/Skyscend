@AbapCatalog.sqlViewName: 'ZVPODETAILS'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Purchase Order Details'
define view ZPODETAILS as select from ekko as head
inner join ekpo as items
    on head.ebeln = items.ebeln {
    key head.ebeln,
    key items.ebelp
        
//    _association_name // Make association public
}
