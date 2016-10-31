@RestResource(urlMapping='/OpportunityProduct')
global with sharing class OpportunityProductRestResource {
    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String INVALID_VALUE_RESPONSE = 'Invalid value: ';
    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';
    global static final String SUCCESS = 'Success';


    global static final String OPPORTUNITY_ID_PARAM = 'opportunity_id';
    global static final String PRODUCTS_PARAM = 'products';

    global class ResponseJSON {
        global String result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }


        global ResponseJSON() {

        }
    }

    public class Product {
        public String product_id;
        public String quantity;
        public String price;
    }

    @HttpPost
    global static String createOpportunityProduct() {
        SystemLogUtil.info(OpportunityProductRestResource.class.toString(), '"createOpportunityProduct" request', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        try{
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            String opportunityId = parameters.get(OPPORTUNITY_ID_PARAM);
            String product = parameters.get(PRODUCTS_PARAM);

            String error = '';
            if (String.isBlank(opportunityId)) {
                error += FIELD_MISSING_RESPONSE + OPPORTUNITY_ID_PARAM + '\n';
            } else if (String.isBlank(product)) {
                error += FIELD_MISSING_RESPONSE + PRODUCTS_PARAM + '\n';
            }

            String accountType = '';
            String opptyRecordType = '';
            if(!String.isBlank(opportunityId)) {
                //Search AccountId using contactId
                List<Opportunity> opportunity = [Select Member_Non_Member__c, RecordType.Name from Opportunity where Id =:opportunityId];
                if(opportunity.isEmpty()) {
                    error += INVALID_VALUE_RESPONSE + OPPORTUNITY_ID_PARAM + '\n';
                } else {
                    accountType = opportunity[0].Member_Non_Member__c;
                    opptyRecordType = opportunity[0].RecordType.Name;
                }
            }

            if (!String.isBlank(error)) {
                response.error = error;
                response.code = 500;
            } else {

                //Getting pricebookEntryId for each Product Id;
                Map<Id, Id> productMap = getProductMap(accountType, opptyRecordType);
                //Map<Id, Id> productMap = getProductMapSandbox(accountType); /
                List<Product> products = (List<Product>)System.JSON.deserialize(product, List<Product>.class);
                system.debug('%productMap:'+productMap);
                system.debug('%products:'+products);

                List<OpportunityLineItem> olines = new List<OpportunityLineItem>();
                for(Product prod : products) {
                    OpportunityLineItem ol = new OpportunityLineItem();
                    ol.OpportunityId = opportunityId;
                    ol.Quantity = String.isBlank(prod.quantity) ? 0 : decimal.valueof(prod.quantity);
                    ol.PricebookEntryId = productMap.get(prod.product_id);
                    ol.TotalPrice = String.isBlank(prod.price) ? 0 : decimal.valueof(prod.price);
                    olines.add(ol);
                }

                insert (olines);

                Map<Id, Id> olineIdAndProductIdMap = new Map<Id, Id>();

                for (OpportunityLineItem ol : olines) {
                    for (Product prod : products) {
                        if (productMap.get(prod.product_id) == ol.PricebookEntryId) {
                            olineIdAndProductIdMap.put(prod.product_id, ol.Id);
                            break;
                        }
                    }
                }

                response.result = JSON.serialize(olineIdAndProductIdMap);
                response.code = 200;
            }
        } catch (Exception e) {
            // Update the response details record with the exception error message
           response.error = UNEXPECTED_EXCEPTION + e.getMessage() + e.getStackTraceString();
           response.code = 500;
        }

        SystemLogUtil.info(OpportunityProductRestResource.class.toString(), '"createOpportunityProduct" response', String.valueOf(response));

        return JSON.serialize(response);
    }

    @HttpGet
    global static void getOpportunityProducts() {
        SystemLogUtil.info(OpportunityProductRestResource.class.toString(), '"getOpportunityProduct" called', String.valueOf(RestContext.request));

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, String> smap = req.params;

        if (smap.containsKey('opportunity_id')  && !String.isBlank(smap.get('opportunity_id'))) {
            List<OpportunityLineItem> olines = [SELECT id, Product2Id from OpportunityLineItem where OpportunityId = :smap.get('opportunity_id')];
            if (olines.size() > 0) {
                res.statusCode= 200;
                res.responseBody = Blob.valueOf(JSON.serialize(olines));
            } else {
                System.debug('No opportunity products found');
                res.statusCode = 404;
            }

             SystemLogUtil.info(OpportunityProductRestResource.class.toString(), '"getOpportunityProduct" response', String.valueOf(JSON.serialize(olines)));            
        }
    }

    private static Map<Id, Id> getProductMap(String accountType, String opptyRecordType) {
        String pricebookId = '';
        Map<Id, Id> productMap = new Map<Id, Id>();
        String pricebookName = '';
        if(accountType.equals('Member')) {
            pricebookName = 'Member';
            //pricebookName = (opptyRecordType == 'Education' ?  'Education Member' : (opptyRecordType == 'Events' ? 'Events Member' : (opptyRecordType == 'Resource' ? 'Resource Member' : 'Standard Price Book')));
        } else if(accountType.equals('Non-Member')) {
            pricebookName = 'Non Member';
            //pricebookName = (opptyRecordType == 'Education' ?  'Education Non Members' : (opptyRecordType == 'Events' ? 'Events Non Member' : (opptyRecordType == 'Resource' ? 'Resource Non Member' : 'Standard Price Book')));
        }

        Pricebook2 pricebook = [Select Id from Pricebook2 where Name = :pricebookName];

        for(PricebookEntry pbe : [Select Id, Product2Id from PricebookEntry where pricebook2Id = :pricebook.Id]) {
            if(!productMap.containsKey(pbe.Product2Id)) {
                productMap.put(pbe.Product2Id, pbe.Id);
            }
        }
        return productMap;
    }
}