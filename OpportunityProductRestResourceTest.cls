/**
 * Tests for ContactRestResourceTest.cls
 *
 * @author Jon Kenny, John Au, Katherine Idarraga (Trineo)
 */
 @IsTest
private class OpportunityProductRestResourceTest {
	@testSetup static void setup() {

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

        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Contact';
        contact.Terms_Conditions__c = true;
        insert contact;

        //Create Education Opportunity
        Id opportunityRecordType = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Education').RecordTypeId;
        Opportunity opportunity = new Opportunity();
        opportunity.RecordTypeId = opportunityRecordType;
        opportunity.Name = 'Online Education Purchase';
        opportunity.AccountId = account.Id;
        opportunity.StageName = 'Closed Paid';
        opportunity.CloseDate = System.today();
        opportunity.Amount = 1000;
        insert opportunity;

        //Create Education Pricebook, Product and PricebookEntry
        Product2 product = new Product2();
		product.Name = 'Education Product';
		product.Points__c = 10;
		insert product;

        product.Id_Prod__c = product.Id;
        update product;

		PricebookEntry PBEStd = new PricebookEntry();
		PBEStd.Product2Id = product.Id;
		PBEStd.Pricebook2Id = Test.getStandardPricebookId();
		PBEStd.UnitPrice = 1;
		PBEStd.IsActive = true;
		insert PBEStd;

		List<Pricebook2> pb = [Select Id from Pricebook2 where isActive = true and Name = 'Member'];
		Pricebook2 pricebook;
		if(pb.isEmpty()) {
			pricebook = new Pricebook2();
			pricebook.Name = 'Member';
			pricebook.IsActive=true;
			insert pricebook;
		} else {
			pricebook = pb[0];
		}
		
		PricebookEntry PBE = new PricebookEntry();
		PBE.Product2Id = product.Id;
		PBE.Pricebook2Id = pricebook.Id;
		PBE.UnitPrice = 100;
		PBE.IsActive = true;
		PBE.UseStandardPrice = false;
		insert PBE;

        //Create Events Opportunity
        Id opportunityRecordType1 = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Events').RecordTypeId;
        Opportunity opportunity1 = new Opportunity();
        opportunity1.RecordTypeId = opportunityRecordType1;
        opportunity1.Name = 'Online Event Purchase';
        opportunity1.AccountId = account.Id;
        opportunity1.StageName = 'Confirmed';
        opportunity1.CloseDate = System.today();
        opportunity1.Amount = 1000;
        insert opportunity1;

        //Create Events Pricebook, Product and PricebookEntry
        Product2 product1 = new Product2();
        product1.Name = 'Event Product';
        product1.Points__c = 10;
        insert product1;

        product1.Id_Prod__c = product1.Id;
        update product1;

        PricebookEntry PBEStd1 = new PricebookEntry();
        PBEStd1.Product2Id = product1.Id;
        PBEStd1.Pricebook2Id = Test.getStandardPricebookId();
        PBEStd1.UnitPrice = 1;
        PBEStd1.IsActive = true;
        insert PBEStd1;
        
        PricebookEntry PBE1 = new PricebookEntry();
        PBE1.Product2Id = product1.Id;
        PBE1.Pricebook2Id = pricebook.Id;
        PBE1.UnitPrice = 100;
        PBE1.IsActive = true;
        PBE1.UseStandardPrice = false;
        insert PBE1;

        //Create Resource Opportunity
        Id opportunityRecordType2 = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Resource').RecordTypeId;
        Opportunity opportunity2 = new Opportunity();
        opportunity2.RecordTypeId = opportunityRecordType2;
        opportunity2.Name = 'Online Resource Purchase';
        opportunity2.AccountId = account.Id;
        opportunity2.StageName = 'Confirmed';
        opportunity2.CloseDate = System.today();
        opportunity2.Amount = 1000;
        insert opportunity2;

        //Create Resource Pricebook, Product and PricebookEntry
        Product2 product2 = new Product2();
        product2.Name = 'Resource Product';
        product2.Points__c = 10;
        insert product2;

        product2.Id_Prod__c = product2.Id;
        update product2;

        PricebookEntry PBEStd2 = new PricebookEntry();
        PBEStd2.Product2Id = product2.Id;
        PBEStd2.Pricebook2Id = Test.getStandardPricebookId();
        PBEStd2.UnitPrice = 1;
        PBEStd2.IsActive = true;
        insert PBEStd2;
        
        PricebookEntry PBE2 = new PricebookEntry();
        PBE2.Product2Id = product2.Id;
        PBE2.Pricebook2Id = pricebook.Id;
        PBE2.UnitPrice = 100;
        PBE2.IsActive = true;
        PBE2.UseStandardPrice = false;
        insert PBE2;
    }

	/**
     * Tests response when 'opportunity_id' parameter is missing
     */
    @IsTest
    private static void testEmptyOpportunity() {
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', '');
        restRequest.addParameter('products', 'Test');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = OpportunityProductRestResource.createOpportunityProduct();
	    Test.stopTest();
	    System.assertEquals(true, result.contains(OpportunityRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests response when 'products' parameter is missing
     */
     @IsTest
    private static void testEmptyProducts() {
    	Opportunity opp = [Select Id from Opportunity LIMIT 1];

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', opp.Id);
        restRequest.addParameter('products', '');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityProductRestResource.createOpportunityProduct();
        Test.stopTest();
        System.assertEquals(true, result.contains(OpportunityRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests response when 'opportunity_id' parameter is invalid
     */
    @IsTest
    private static void testInvalidValue() {
    	Opportunity opp = [Select Id from Opportunity LIMIT 1];

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', '12345');
        restRequest.addParameter('products', 'Test');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityProductRestResource.createOpportunityProduct();
        Test.stopTest();
        System.assertEquals(true, result.contains(OpportunityRestResource.INVALID_VALUE_RESPONSE));
    }

    /**
     * Tests successful response
     */
     //Education
	@IsTest
    private static void testCreateEducationOpportunityProduct() {
    	Pricebook2 pb = [Select Id from Pricebook2 where isActive = true and Name = 'Member'];
        Product2 p = [Select Id from Product2 where Name = 'Education Product'];

    	Opportunity opp = [Select Id from Opportunity where Name = 'Online Education Purchase'];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', opp.Id);
        restRequest.addParameter('products','[{"product_id": "'+p.Id+'", "quantity": "1", "price": "1500"},{"product_id":"'+p.Id+'","quantity":2,"price":1000}]');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = OpportunityProductRestResource.createOpportunityProduct();
	        system.debug('%result:'+result);
	    Test.stopTest();
	    System.assertEquals(true, result.contains('200'));
    }
    //Events
    @IsTest
    private static void testCreateEventsOpportunityProduct() {
        Pricebook2 pb = [Select Id from Pricebook2 where isActive = true and Name = 'Member'];
        Product2 p = [Select Id from Product2 where Name = 'Event Product'];

        Opportunity opp = [Select Id from Opportunity where Name = 'Online Event Purchase'];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', opp.Id);
        restRequest.addParameter('products','[{"product_id": "'+p.Id+'", "quantity": "1", "price": "1500"},{"product_id":"'+p.Id+'","quantity":2,"price":1000}]');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityProductRestResource.createOpportunityProduct();
            system.debug('%result:'+result);
        Test.stopTest();
        System.assertEquals(true, result.contains('200'));
    }
    //Resource
    @IsTest
    private static void testCreateResourceOpportunityProduct() {
        Pricebook2 pb = [Select Id from Pricebook2 where isActive = true and Name = 'Member'];
        Product2 p = [Select Id from Product2 where Name = 'Resource Product'];

        Opportunity opp = [Select Id from Opportunity where Name = 'Online Resource Purchase'];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('opportunity_id', opp.Id);
        restRequest.addParameter('products','[{"product_id": "'+p.Id+'", "quantity": "1", "price": "1500"},{"product_id":"'+p.Id+'","quantity":2,"price":1000}]');
        RestContext.request = restRequest;

        Test.startTest();
            String result = OpportunityProductRestResource.createOpportunityProduct();
            system.debug('%result:'+result);
        Test.stopTest();
        System.assertEquals(true, result.contains('200'));
    }
}