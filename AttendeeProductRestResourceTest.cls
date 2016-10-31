/**
 * Tests for ContactRestResourceTest.cls
 *
 * @author Jon Kenny, John Au, Katherine Idarraga (Trineo)
 */
 @IsTest
private class AttendeeProductRestResourceTest {
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

        Id opportunityRecordType = Schema.SObjectType.Opportunity.RecordTypeInfosByName.get('Education').RecordTypeId;
        Opportunity opportunity = new Opportunity();
        opportunity.RecordTypeId = opportunityRecordType;
        opportunity.Name = 'Online Education Purchase';
        opportunity.AccountId = account.Id;
        opportunity.StageName = 'Closed Paid';
        opportunity.CloseDate = System.today();
        opportunity.Amount = 1000;
        insert opportunity;

        //Create Pricebook, Product and PricebookEntry
        Product2 product = new Product2();
		product.Name = 'Test Product';
        product.LMS_Code__c = 'XXXXXX';
		product.Points__c = 10;
		insert product;

		PricebookEntry PBEStd = new PricebookEntry();
		PBEStd.Product2Id = product.Id;
		PBEStd.Pricebook2Id = Test.getStandardPricebookId();
		PBEStd.UnitPrice = 1;
		PBEStd.IsActive = true;
		insert PBEStd;

		List<Pricebook2> pb = [Select Id from Pricebook2 where isActive = true and Name = 'Education Member'];
		Pricebook2 pricebook;
		if(pb.isEmpty()) {
			pricebook = new Pricebook2();
			pricebook.Name = 'Education Member';
			pricebook.IsActive=true;
			insert pricebook;
		} else {
			pricebook = pb[0];
		}

		PricebookEntry pbe = new PricebookEntry();
		pbe.Product2Id = product.Id;
		pbe.Pricebook2Id = pricebook.Id;
		pbe.UnitPrice = 100;
		pbe.IsActive = true;
		pbe.UseStandardPrice = false;
		insert pbe;

		OpportunityLineItem oppProduct = new OpportunityLineItem();
		oppProduct.OpportunityId = opportunity.Id;
        oppProduct.Quantity = 2;
        oppProduct.PricebookEntryId = pbe.Id;
        oppProduct.TotalPrice = 200;
        insert oppProduct;
    }

	/**
     * Tests response when 'contact_id' parameter is missing
     */
    @IsTest
    private static void testEmptyOpportunity() {
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', '');
        restRequest.addParameter('product_id', '123');
        restRequest.addParameter('mobile_num', '0406000000');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = AttendeeProductRestResource.createAttendeeProduct();
	    Test.stopTest();
	    System.assertEquals(true, result.contains(AttendeeProductRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests response when 'opportunity_products' parameter is missing
     */
     @IsTest
    private static void testEmptyProducts() {
    	Contact contact = [Select Id from Contact];

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', contact.Id);
        restRequest.addParameter('product_id', '');
        restRequest.addParameter('mobile_num', '0406000000');
        RestContext.request = restRequest;

        Test.startTest();
            String result = AttendeeProductRestResource.createAttendeeProduct();
        Test.stopTest();
        System.assertEquals(true, result.contains(AttendeeProductRestResource.FIELD_MISSING_RESPONSE));
    }

    /**
     * Tests successful response
     */
	@IsTest
    private static void testCreateAttendeeProduct() {
    	Contact contact = [Select Id from Contact];
    	OpportunityLineItem oppProduct = [Select Id from OpportunityLineItem];
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('contact_id', contact.Id);
        restRequest.addParameter('product_id', oppProduct.Id);
        restRequest.addParameter('mobile_num', '0406000000');
        RestContext.request = restRequest;

        Test.startTest();
	        String result = AttendeeProductRestResource.createAttendeeProduct();
	        system.debug('%result:'+result);
	    Test.stopTest();
	    System.assertEquals(true, result.contains('200'));

	    OpportunityLineItem oppProductToValidate = [Select Id, Attendee_Product__c from OpportunityLineItem];
	    system.assertNotEquals(null, oppProductToValidate.Attendee_Product__c);

	    List<Attendee__c> attendeeToValidate = [Select Id From Attendee__c Where Attendee_Product__c = :oppProductToValidate.Attendee_Product__c and Contact__c = :contact.Id];
	    system.assertEquals(false, attendeeToValidate.isEmpty());
    }

    public class LMSMock implements HttpCalloutMock {

        public System.HttpResponse respond(System.HttpRequest request) {
            HttpResponse res = new HttpResponse();

            res.setStatusCode(200);

            return res;
        }
    }

    @IsTest
    private static void testRegisterForLesson() {
        Test.setMock(HttpCalloutMock.class, new LMSMock());

        Test.startTest();

        Boolean success = AttendeeProductRestResource.registerForLesson('test@test.com', '200');

        Test.stopTest();

        System.assertEquals(true, success);
    }

    @IsTest
    private static void testRegisterForCourse() {
        Test.setMock(HttpCalloutMock.class, new LMSMock());

        Test.startTest();

        Boolean success = AttendeeProductRestResource.registerForCourse('test@test.com', '200');

        Test.stopTest();

        System.assertEquals(true, success);
    }
}