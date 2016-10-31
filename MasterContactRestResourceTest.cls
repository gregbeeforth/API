/**
 * Tests for MasterContactRestResource.cls
 *
 * @author Greg Beeforth (Trineo)
 */
@IsTest
private class MasterContactRestResourceTest {

    @testSetup
    private static void testSetup() {
        Id personAccountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Person Account').RecordTypeId;
        Account personAccount = new Account();
        personAccount.RecordTypeId = personAccountRecordType;
        personAccount.LastName = 'PersonTest';
        insert personAccount;

        Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Member').RecordTypeId;
        Account account = new Account();
        account.RecordTypeId = accountRecordType;
        account.Name = 'Member';
        account.Website = 'http://www.adma.com.au';
        account.Type = 'Agency';
        account.Domain__c = 'adma.com.au';
        account.Industry = 'Accounting Services';
        account.ADMA_Member__c = true;
        insert account;

        Id contactRecordType = Schema.SObjectType.Contact.RecordTypeInfosByName.get('Business').RecordTypeId;
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test';
        contact.Account = account;
        insert contact;

        Master_Contact__c masterContact = new Master_Contact__c();
        masterContact.Person_Account__c = personAccount.Id;
        masterContact.Name = 'Test1';
        insert masterContact;

        Master_Contact__c masterContact1 = new Master_Contact__c();
        masterContact1.Person_Account__c = personAccount.Id;
        masterContact1.Contact__c = contact.Id;
        masterContact1.Name = 'Test2';
        insert masterContact1;

    }

    @IsTest
    private static void testCreateMasterContact() {
        List<Account> account = [SELECT Id from Account where LastName = 'PersonTest'];
        List<Contact> contact = [SELECT Id from Contact where LastName = 'Test'];

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('person_account_id', account[0].Id);
        restRequest.addParameter('contact_id', contact[0].Id);
        RestContext.request = restRequest;

        Test.startTest();
            String result = MasterContactRestResource.createMasterContact();
            system.debug('%result:'+result);
        Test.stopTest();
        System.assertEquals(true, result.contains('200'));
    }    

    @IsTest
    private static void testUpdateMasterContact() {

        List<Master_Contact__c> masterContact = [SELECT Id from Master_Contact__c where Name = 'Test1'];
        List<Contact> contact = [SELECT Id from Contact where LastName = 'Test'];

        RestRequest restRequest = new RestRequest();
        restRequest.addParameter('master_contact_id', masterContact[0].Id);
        restRequest.addParameter('contact_id', contact[0].Id);
        RestContext.request = restRequest;

        Test.startTest();
        String result = MasterContactRestResource.createMasterContact();
        system.debug('%result:'+result);

        System.assertEquals(true, result.contains('200'));

        Test.stopTest();
    }


    @IsTest
    private static void testFindMasterContact() {
        
        List<Master_Contact__c> masterContact= [SELECT Id, Person_Account__c, Contact__c from Master_Contact__c WHERE Name = 'Test2'];
        List<Account> account = [SELECT Id from Account where LastName = 'PersonTest'];
        List<Contact> contact = [SELECT Id from Contact where LastName = 'Test'];

        Test.startTest();

            RestRequest restRequest = new RestRequest();
            restRequest.addParameter('master_contact_id', masterContact[0].Id);
            RestContext.request = restRequest;
            String result = MasterContactRestResource.findMasterContact();

            system.debug('GREGB: ' + masterContact);
            system.debug('GREGB: ' + contact[0].Id);
            system.debug('GREGB: ' + account[0].Id);

            RestRequest restRequest1 = new RestRequest();
            restRequest1.addParameter('contact_id', contact[0].Id);
            restRequest1.addParameter('person_account_id', account[0].Id);
            RestContext.request = restRequest1;
            String result1 = MasterContactRestResource.findMasterContact();


            RestRequest restRequest2 = new RestRequest();
            restRequest2.addParameter('person_account_id', account[0].Id);
            RestContext.request = restRequest2;
            String result2 = MasterContactRestResource.findMasterContact();


            RestRequest restRequest3 = new RestRequest();
            restRequest3.addParameter('contact_id', contact[0].Id);
            RestContext.request = restRequest3;
            String result3 = MasterContactRestResource.findMasterContact();


        Test.stopTest();

            System.assertEquals(true, result.contains('200'));
            System.assertEquals(true, result1.contains('200'));
            System.assertEquals(true, result2.contains('200'));
            System.assertEquals(true, result3.contains('200'));

    }

}