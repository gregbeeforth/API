@RestResource(urlMapping='/Payments')
global with sharing class PaymentRestResource {
    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';

    global static final String OPP_ID_PARAM = 'opportunity_id';
    global static final String METHOD_PARAM = 'method';
    global static final String REMOTE_ID_PARAM = 'remote_id';
    global static final String MESSAGE_PARAM = 'message';
    global static final String STATUS_PARAM = 'status';
    global static final String AMOUNT_PARAM = 'amount';
    global static final String PMNT_ID_PARAM = 'payment_id';
    global static final String CARD_TYPE_PARAM = 'card_type';


    global class ResponseJSON {

        global String result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() {

        }
    }

    @httpPost
    global static String createPayment() {
        SystemLogUtil.info(PaymentRestResource.class.toString(), 'createPayment called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            String oppId = parameters.get(OPP_ID_PARAM);
            String paymentMethod = parameters.get(METHOD_PARAM);
            String remoteId = parameters.get(REMOTE_ID_PARAM);
            String message = parameters.get(MESSAGE_PARAM);
            String status = parameters.get(STATUS_PARAM);
            String amount = parameters.get(AMOUNT_PARAM);
            String paymentId = parameters.get(PMNT_ID_PARAM);
            String cardtype = parameters.get(CARD_TYPE_PARAM);

            Boolean isUpdate = !String.isBlank(paymentId);

            Payment__c payment = new Payment__c();

            
            String error = '';
            if(!isUpdate){
                if (String.isBlank(oppId)) {
                    error += FIELD_MISSING_RESPONSE + OPP_ID_PARAM + '\n';
                }
                if (String.isBlank(paymentMethod)) {
                    error += FIELD_MISSING_RESPONSE + METHOD_PARAM + '\n';
                }
                if (String.isBlank(message)) {
                    error += FIELD_MISSING_RESPONSE + MESSAGE_PARAM + '\n';
                }
                if (String.isBlank(status)) {
                    error += FIELD_MISSING_RESPONSE + STATUS_PARAM + '\n';
                }
                if (String.isBlank(amount)) {
                    error += FIELD_MISSING_RESPONSE + AMOUNT_PARAM + '\n';
                }
            }

            if (isUpdate) {
                if (String.isBlank(status)) {
                    error += FIELD_MISSING_RESPONSE + STATUS_PARAM + '\n';
                }
                try {
                    payment = [Select Id, Status__c From Payment__c Where Id = :paymentId];
                } catch (Exception e) {
                    System.debug(e);
                    error += 'Invalid Payment ID: ' + paymentId + '. Error attempting to retrieve Payment record';
                }
            }

            //missing a required field- don't insert the contact and chuck an error
            if (!String.isBlank(error)) {
                response.error = error;
                response.code = 500;

                return JSON.serialize(response);
            }

            if(!isUpdate){
                payment.Opportunity__c = oppId;
                payment.Payment_Method__c = paymentMethod;
                payment.Remote_Id__c = remoteId;
                payment.Message__c = message;
                payment.Status__c = status;
                payment.Card_Type__c = cardtype;
                payment.Amount__c = String.isBlank(amount) ? 0 : decimal.valueof(amount);

                insert(payment);

                //response.result = 'Success';
                response.result = payment.Id;
                response.code = 200;
            }

            if(isUpdate){
                payment.Status__c = status;
                update(payment);
            }

        } catch (Exception e) {
            response.error = UNEXPECTED_EXCEPTION + e.getMessage();
            response.code = 500;
        }

        SystemLogUtil.info(PaymentRestResource.class.toString(), 'createPayment response', String.valueOf(response));

        return JSON.serialize(response);
    }
}