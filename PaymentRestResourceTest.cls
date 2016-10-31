@IsTest
private class PaymentRestResourceTest {

    @IsTest
    private static void testSuccess() {
        RestRequest restRequest = new RestRequest();

        Xero_Setting__c xeroSetting = TestObjectFactory.getXeroSettings('AU', 'privateKey', '123456789', 'consumerSecret', true);

        Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;
        Account account = new Account();
        account.Name = 'ADMA';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'adma.com.au';
        account.Industry = 'Accounting Services';
        account.ADMA_Member__c = true;
        insert account;

        Id opportunityRecordType = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Education').RecordTypeId;
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = opportunityRecordType;
        opp.Name = 'Online Education Purchase';
        opp.AccountId = account.Id;
        opp.StageName = 'Closed Paid';
        opp.CloseDate = System.today();
        opp.Amount = 1000;
        insert opp;

        //Create Payment
        restRequest.addParameter('opportunity_id', String.valueOf(opp.Id));
        restRequest.addParameter('method', 'Credit Card');
        restRequest.addParameter('message', 'Test payment message');
        restRequest.addParameter('status', 'Test payment status');
        restRequest.addParameter('amount', String.valueOf(2000));
        restRequest.addParameter('remoteId', 'remote id');

        RestContext.request = restRequest;

        String responseJSON = PaymentRestResource.createPayment();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);

        System.assertNotEquals(null, response.get('result'));
        System.assert(response.get('result') instanceof Id);

        Payment__c payment = new Payment__c();
        payment = [Select Id from Payment__c limit 1];

        //Missing Parameters
        restRequest.addParameter('opportunity_id', '');

        RestContext.request = restRequest;

        responseJSON = PaymentRestResource.createPayment();

        response = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);

        //Test Update
        restRequest.addParameter('payment_id', payment.Id);
        restRequest.addParameter('status', 'Test payment status2');

        RestContext.request = restRequest;

        responseJSON = PaymentRestResource.createPayment();

        response = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);

        //Test Update with no Status Parameter
        restRequest.addParameter('payment_id', payment.Id);
        restRequest.addParameter('status', '');

        RestContext.request = restRequest;

        responseJSON = PaymentRestResource.createPayment();

        response = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);


    }
}