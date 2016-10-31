@RestResource(urlMapping='/CreateOpportunity')
global with sharing class OpportunityRestResource {
    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String INVALID_VALUE_RESPONSE = 'Invalid value: ';
    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';
    global static final String SUCCESS = 'Success';


    global static final String CONTACT_ID_PARAM = 'contact_id';
    global static final String AMOUNT_PARAM = 'amount';
    global static final String PRODUCT_FAMILY_PARAM = 'product_family';
    global static final String DISCOUNT_CODE_PARAM = 'discount_code';
    //global static final String PRODUCT_NAME_PARAM = 'product_name';

    global class ResponseJSON {
        global String result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() {

        }
    }

    @HttpPost
    global static String createOpportunity() {
        SystemLogUtil.info(OpportunityRestResource.class.toString(), '"createOpportunity" called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned
        try{
            String result  = '';

            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            String contactId = parameters.get(CONTACT_ID_PARAM);
            String amount = parameters.get(AMOUNT_PARAM);
            String productFamily = parameters.get(PRODUCT_FAMILY_PARAM);
            String discountCode= parameters.get(DISCOUNT_CODE_PARAM);
            //String productName = parameters.get(PRODUCT_NAME_PARAM);

            String error = '';
            if (String.isBlank(contactId)) {
                error += FIELD_MISSING_RESPONSE + CONTACT_ID_PARAM + '\n';
            } else if (String.isBlank(amount)) {
                error += FIELD_MISSING_RESPONSE + AMOUNT_PARAM + '\n';
            } else if (String.isBlank(productFamily)) {
                error += FIELD_MISSING_RESPONSE + PRODUCT_FAMILY_PARAM + '\n';
            }

            if(productFamily == 'Events' || productFamily == 'Education' || productFamily == 'Resource'){
                //No Error
            }
            else
            {
                error += INVALID_VALUE_RESPONSE + PRODUCT_FAMILY_PARAM + '\n'; 
            }

            String accountId = '';
            if(!String.isBlank(contactId)) {
                //Search AccountId using contactId
                List<Contact> contact = [Select AccountId, Name from Contact where Id =:contactId];
                if(contact.isEmpty()) {
                    error += INVALID_VALUE_RESPONSE + CONTACT_ID_PARAM + '\n';
                } else {
                    accountId = contact[0].AccountId;
                }
            }

            if (!String.isBlank(error)) {
                response.error = error;
                response.code = 500;
            } else {

                //Id opportunityRecordType = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Education').RecordTypeId;
                Id opportunityRecordType = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get(productFamily).RecordTypeId;
                Opportunity o = new Opportunity();
                //o.Name = (productfamily == 'Education' ?  'Online Education Purchase' : 'Online Event Purchase');
                o.Name = (productfamily == 'Education' ?  'Online Education Purchase' : (productfamily == 'Events' ? 'Online Event Purchase' : 'Online Resource Purchase'));
                o.RecordTypeId = opportunityRecordType;
                o.AccountId = accountId;
                o.Amount = String.isBlank(amount) ? 0 : decimal.valueof(amount);
                o.StageName = 'Activated';
                o.CloseDate = system.today();
                o.Contact__c = contactId;
                o.Discount_Code_Web__c = discountCode;
                insert (o);

                //response.result = SUCCESS;
                response.result = o.Id;
                response.code = 200;
            }

        } catch (Exception e) {
            // Update the response details record with the exception error message
            response.error = UNEXPECTED_EXCEPTION + e.getMessage();
            response.code = 500;
        }

        SystemLogUtil.info(OpportunityRestResource.class.toString(), '"createOpportunity" response', String.valueOf(response));

        return JSON.serialize(response);
    }
}