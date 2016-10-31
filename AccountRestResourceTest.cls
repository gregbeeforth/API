/**
 * Tests for AccountRestResourceTest.cls
 *
 * @author Greg Beeforth (Trineo)
 */
@IsTest
private class AccountRestResourceTest {
  /**
     * Tests response when 'contact_id' parameter is missing
     */
    @IsTest
    private static void testFieldsMissing() {
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('name', '');
        restRequest.addParameter('website', '');
        restRequest.addParameter('type', '');
        restRequest.addParameter('domain', '');
        restRequest.addParameter('industry', '');
        restRequest.addParameter('id', '');

        RestContext.request = restRequest;

        Test.startTest();
          String result = AccountRestResource.createAccount();
        Test.stopTest();
      System.assertEquals(true, result.contains('Missing Accont Name'));
    }

    @IsTest
    private static void testCreateAccount() {
      Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;

        //Successfull Call out
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('name', 'ADMA');
        restRequest.addParameter('website', 'http://www.adma.com.au');
        restRequest.addParameter('type', 'Agency');
        restRequest.addParameter('domain', 'adma.com.au');
        restRequest.addParameter('industry', 'Accounting Services');
        restRequest.addParameter('contact', 'Test Contact');
        restRequest.addParameter('reason', 'Test Reason');
        restRequest.addParameter('employees', '50');
        restRequest.addParameter('email', 'test@mail.com');
        restRequest.addParameter('phone', '0406123321');
        restRequest.addParameter('contactmethod', 'Email');
        restRequest.addParameter('revenue', '50');
        restRequest.addParameter('membership', 'Gold');
        restRequest.addParameter('id', '');

        RestContext.request = restRequest;

        Test.startTest();
          
        String result = AccountRestResource.createAccount();
        System.assertEquals(true, result.contains('200'));

        List<Account> testAccountUpdate = [Select Id from Account where name = 'ADMA'];
        string accountId = testAccountUpdate[0].Id;

        //Id sent - update occurs
        restRequest = new RestRequest();
        restRequest.addParameter('name', 'ADMA');
        restRequest.addParameter('website', 'http://www.adma.com.au');
        restRequest.addParameter('type', 'Agency');
        restRequest.addParameter('domain', 'adma.com.au');
        restRequest.addParameter('industry', 'Financial Services');
        restRequest.addParameter('id', accountId);

        RestContext.request = restRequest;

        result = AccountRestResource.createAccount();
        System.assertEquals(true, result.contains('200'));

        //Id not found - error returned
        restRequest = new RestRequest();
        restRequest.addParameter('name', 'ADMA');
        restRequest.addParameter('website', 'http://www.adma.com.au');
        restRequest.addParameter('type', 'Agency');
        restRequest.addParameter('domain', 'adma.com.au');
        restRequest.addParameter('industry', 'Accounting Services');
        restRequest.addParameter('id', 'xxxxxxxxxx');

        RestContext.request = restRequest;

        result = AccountRestResource.createAccount();
        System.assertEquals(true, result.contains('500'));

        Test.stopTest();
      
    }

 


    @IsTest
    private static void testFindAccount() {
        Account account = new Account();
        account.Name = 'ADMA Test';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'test.com.au; adma.com.au';
        account.Industry = 'Accounting Services';
        account.ADMA_Member__c = true;
        insert account;

        Account account1 = new Account();
        account1.Name = 'Test';
        account1.Website = 'http://www.test.com.au';
        account1.Type = 'Agency';
        account1.Domain__c = 'test.com.au';
        account1.Industry = 'Accounting Services';
        account1.ADMA_Member__c = true;
        insert account1;

        Test.startTest(); 
        //Test domain retrieval
        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('domain', 'adma.com.au');
        RestContext.request = restRequest;
   
        List<Account> testAccounts = AccountRestResource.findAccount();
        System.assert(testAccounts.size()==1);

        //test ID retrieval
        restRequest = new RestRequest();
        restRequest.addParameter('id', account1.Id);
        RestContext.request = restRequest;

        List<Account> testAccounts2 = AccountRestResource.findAccount();
        System.assertequals(testAccounts2[0].Name,'Test');

        //test search retrieval
        restRequest = new RestRequest();
        restRequest.addParameter('search', 'Test');
        RestContext.request = restRequest;

        List<Account> testAccounts3 = AccountRestResource.findAccount();
        System.assert(testAccounts3.size()==2);

        //test get all accounts
        restRequest = new RestRequest();
        RestContext.request = restRequest;

        List<Account> testAccounts4 = AccountRestResource.findAccount();
        System.assert(testAccounts4.size()==2);

        Test.stopTest(); 


    }

}