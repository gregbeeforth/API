/**
 * Tests for ContactRestResourceTest.cls
 *
 * @author Jon Kenny, John Au, Katherine Idarraga (Trineo)
 */
@IsTest
private class ContactRestResourceTest {
	/**
     * Tests response when 'contact_id' parameter is missing
     */
    @IsTest
    private static void testFieldsMissing() {
        RestRequest restRequest = new RestRequest();
        //restRequest.addParameter('first_name', '');
        restRequest.addParameter('last_name', '');
        restRequest.addParameter('email', '');
        //restRequest.addParameter('email_verified', '');
        //restRequest.addParameter('work_email', '');
        //restRequest.addParameter('work_verified', '');
        //restRequest.addParameter('street', '');
        //restRequest.addParameter('suburb', '');
        //restRequest.addParameter('state', '');
        //restRequest.addParameter('postcode', '');
        //restRequest.addParameter('company_name', '');
        //restRequest.addParameter('company_id', '');
        //restRequest.addParameter('newsletter_subscriptions', '');

        RestContext.request = restRequest;

        Test.startTest();
	        String result = ContactRestResource.createContact();
	    Test.stopTest();
	    System.assertEquals(true, result.contains(ContactRestResource.FIELD_MISSING_RESPONSE));
    }

    @IsTest
    private static void testCreateContact() {
    	Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;
        Account account = new Account();
        account.Name = 'ADMA';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'adma.com.au';
        account.Industry = 'Accounting Services';
        account.ADMA_Member__c = true;
        insert account;

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('first_name', 'Test');
        restRequest.addParameter('last_name', 'Contact');
        restRequest.addParameter('email', 'test@gmail.com');
        restRequest.addParameter('email_verified', '1000');
        restRequest.addParameter('work_email', 'true');
        restRequest.addParameter('work_verified', 'true');
        restRequest.addParameter('street', '123 Test Street');
        restRequest.addParameter('suburb', 'Sydney CBD');
        restRequest.addParameter('state', 'NSW');
        restRequest.addParameter('country', 'Australia');
        restRequest.addParameter('postcode', '2000');
        restRequest.addParameter('company_name', 'ADMA');
        restRequest.addParameter('dob', '31/10/1986');
        restRequest.addParameter('dob', '31/10/1986');
        restRequest.addParameter('company_id', account.Id);
        restRequest.addParameter('newsletter_subscriptions', '["news__c","Media__c"]');

        RestContext.request = restRequest;

        Test.startTest();
	        String result = ContactRestResource.createContact();
	        system.debug('%result:'+result);
	    Test.stopTest();
	    System.assertEquals(true, result.contains('200'));
    }

    @IsTest
    private static void testUpdateContact() {
        Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;
        Account account = new Account();
        account.Name = 'ADMA';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'adma.com.au';
        account.Industry = 'Accounting Services';
        account.ADMA_Member__c = true;
        insert account;

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('first_name', 'Test');
        restRequest.addParameter('last_name', 'Contact');
        restRequest.addParameter('email', 'test@gmail.com');
        restRequest.addParameter('email_verified', '1000');
        restRequest.addParameter('work_email', 'true');
        restRequest.addParameter('work_verified', 'true');
        restRequest.addParameter('street', '123 Test Street');
        restRequest.addParameter('suburb', 'Sydney CBD');
        restRequest.addParameter('state', 'NSW');
        restRequest.addParameter('country', 'Australia');
        restRequest.addParameter('postcode', '2000');
        restRequest.addParameter('company_name', 'ADMA');
        restRequest.addParameter('company_id', account.Id);
        restRequest.addParameter('newsletter_subscriptions', '["news__c","Media__c"]');

        RestContext.request = restRequest;

        Test.startTest();
        String result = ContactRestResource.createContact();
        system.debug('%result:'+result);

        System.assertEquals(true, result.contains('200'));

        Contact c = [Select Id, FirstName From Contact Where Email = 'test@gmail.com'];

        System.assertEquals('Test', c.FirstName);

        restRequest = new RestRequest();
        restRequest.addParameter('contact_id', c.Id);
        restRequest.addParameter('first_name', 'McTest');

        RestContext.request = restRequest;

        ContactRestResource.createContact();

        c = [Select Id, FirstName From Contact Where Email = 'test@gmail.com'];

        System.assertEquals('McTest', c.FirstName);
        Test.stopTest();
    }


    @IsTest
    private static void testGetContact() {
        Contact c = new Contact(FirstName = 'Test', LastName = 'McTest', Email = 'test@mctest.com', Terms_Conditions__c = true);

        insert (c);

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('email', 'test@mctest.com');

        RestContext.request = restRequest;

        String result = ContactRestResource.findContact();
        System.assert(result.contains('test@mctest.com'));

        //test ID retrieval

        restRequest = new RestRequest();
        restRequest.addParameter('id', c.Id);

        RestContext.request = restRequest;

        result = ContactRestResource.findContact();
        System.assert(result.contains('test@mctest.com'));
    }

}