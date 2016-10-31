/**
 * Tests for ContactRestResourceTest.cls
 *
 * @author Jon Kenny, John Au, Katherine Idarraga (Trineo)
 */
 @IsTest
private class OpportunityRestResourceTest {
	@testSetup static void setup() {

        Xero_Setting__c xeroSetting = TestObjectFactory.getXeroSettings('AU', 'privateKey', '123456789', 'consumerSecret', true);
        
		Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;
        Account account = new Account();
        account.Name = 'ADMA';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'adma.com.au';
        account.Industry = 'Accounting Services';
        insert account;

        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Contact';
        contact.Terms_Conditions__c = true;
        insert contact;
    }

	/**
     * Tests response when 'contact_id' parameter is missing
     */
    @IsTest
    private static void testEmptyContact() {
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', '');
        restRequest.addParameter('amount', '1000');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = OpportunityRestResource.createOpportunity();
	    Test.stopTest();
	    System.assertEquals(true, result.contains(OpportunityRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests response when 'contact_id' parameter is invalid
     */
    @IsTest
    private static void testInvalidContact() {
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', '12345');
        restRequest.addParameter('amount', '1000');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityRestResource.createOpportunity();
        Test.stopTest();
        System.assertEquals(true, result.contains(OpportunityRestResource.INVALID_VALUE_RESPONSE));
    }

    /**
     * Tests response when 'amount' parameter is missing
     */
    @IsTest
    private static void testInvalidAmountdEmail() {
    	Contact testContact = [Select Id from Contact];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', testContact.Id);
        restRequest.addParameter('amount', '');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = OpportunityRestResource.createOpportunity();
	    Test.stopTest();
	    System.assertEquals(true, result.contains(OpportunityRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests response when incorrect product family sent
     */
    @IsTest
    private static void testCreateInvalidOpportunity() {
        Contact testContact = [Select Id from Contact];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', testContact.Id);
        restRequest.addParameter('amount', '1000');
        restRequest.addParameter('product_family', 'Invalid');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityRestResource.createOpportunity();
        Test.stopTest();
        System.assertEquals(true, result.contains(OpportunityRestResource.INVALID_VALUE_RESPONSE));
    }
    /**
     * Tests successful response
     */
     // Education
	@IsTest
    private static void testCreateEducationOpportunity() {
    	Contact testContact = [Select Id from Contact];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', testContact.Id);
        restRequest.addParameter('amount', '1000');
        restRequest.addParameter('product_family', 'Education');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = OpportunityRestResource.createOpportunity();
            system.debug('%'+result);
	    Test.stopTest();
	    System.assertEquals(true, result.contains('200'));
    }
    // Events
    @IsTest
    private static void testCreateEventsOpportunity() {
        Contact testContact = [Select Id from Contact];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', testContact.Id);
        restRequest.addParameter('amount', '1000');
        restRequest.addParameter('product_family', 'Events');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityRestResource.createOpportunity();
            system.debug('%'+result);
        Test.stopTest();
        System.assertEquals(true, result.contains('200'));
    }
    // Resource
    @IsTest
    private static void testCreateResourceOpportunity() {
        Contact testContact = [Select Id from Contact];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', testContact.Id);
        restRequest.addParameter('amount', '1000');
        restRequest.addParameter('product_family', 'Resource');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityRestResource.createOpportunity();
            system.debug('%'+result);
        Test.stopTest();
        System.assertEquals(true, result.contains('200'));
    }
}