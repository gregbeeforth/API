/**
 * Rest API that takes a Person Account Id and Contact Id
 * then creates a Master Contact record linking the two. Both inputs are optional
 *
 * @author Greg Beeforth (Trineo)
 **/
@RestResource(urlMapping='/MasterContact')
global with sharing class MasterContactRestResource {

    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String RECORD_MISSING_RESPONSE = 'Record does not exist: ';

    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';

    global static final String MASTER_CONTACT_ID_PARAM = 'master_contact_id';
    global static final String PERSON_ACCOUNT_ID_PARAM = 'person_account_id';
    global static final String CONTACT_ID_PARAM = 'contact_id';

    global class ResponseJSON {

        global Object result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() {

        }
    }

    @HttpPost
    global static String createMasterContact() {
        SystemLogUtil.info(MasterContactRestResource.class.toString(), '"createMasterContact" called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            String masterContactId = parameters.get(MASTER_CONTACT_ID_PARAM);
            String personAccountId = parameters.get(PERSON_ACCOUNT_ID_PARAM);
            String contactId = parameters.get(CONTACT_ID_PARAM);

            Boolean isUpdate = !String.isBlank(masterContactId);

            String error = '';

            Master_Contact__c mc = new Master_Contact__c();

            if (isUpdate) {
                try {
                    mc = [Select Id From Master_Contact__c Where Id = :masterContactId];
                } catch (Exception e) {
                    System.debug(e);
                    error += 'Invalid Master Contact ID: ' + masterContactId + '. Error attempting to retrieve Master Contact record';
                    response.error = error;
                    response.code = 500;

                    return JSON.serialize(response);
                }
            }

            if (!String.isBlank(personAccountId)) {
                //Check to see person account exists
                List<Account> a = [Select Id, Name From Account Where Id = :personAccountId and isPersonAccount = true ];
                if (a.size()>0){
                    mc.Person_Account__c = personAccountId;
                    mc.Name = a[0].Name;  
                }
                else {
                    error += RECORD_MISSING_RESPONSE + PERSON_ACCOUNT_ID_PARAM + '\n';    
                }        
            }

            if (!String.isBlank(contactId)) {
                //Check to see contact exists
                List<Contact> c = [Select Id, Name From Contact Where Id = :contactId];
                if (c.size()>0){
                    mc.Contact__c = contactId;
                    mc.Name = c[0].Name;  
                }
                else {
                    error += RECORD_MISSING_RESPONSE + CONTACT_ID_PARAM + '\n';    
                }        
            }

            //not an 'update' and missing a required field- don't insert the contact and chuck an error
            if (!String.isBlank(error) && !isUpdate) {
                response.error = error;
                response.code = 500;

                return JSON.serialize(response);
            }

            if (!isUpdate) {
                insert (mc);
            } else {
                update (mc);
            }

            response.result = mc.Id;
            response.code = 200;
        } catch (Exception e) {
            response.error = UNEXPECTED_EXCEPTION + e.getMessage();
            response.code = 500;
        }

        SystemLogUtil.info(MasterContactRestResource.class.toString(), '"createMasterContact" response', String.valueOf(response));

        return JSON.serialize(response);
    }


    /**
     * API that takes a contact id and returns details for the matching contact record
     **/
    @HttpGet
    global static String findMasterContact() {
        SystemLogUtil.info(MasterContactRestResource.class.toString(), '"findMasterContact" called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        RestRequest rr = RestContext.request;
        Map<String, String> smap = rr.params;

        if (smap.containsKey('master_contact_id')  && !String.isBlank(smap.get('master_contact_id'))) {
            List<Master_Contact__c> masterContacts = [select
                                        Id,
                                        Name,
                                        Contact__c,
                                        Person_Account__c
                                    from
                                        Master_Contact__c
                                    where
                                        id = :smap.get('master_contact_id')];
            if (masterContacts.size() > 0) {
                response.code = 200;
                response.result = masterContacts;
            } else {
                System.debug('No Master Contact found');
                response.code = 404;
                response.result = 'No Master Contact found';
            }
        } else if (smap.containsKey('person_account_id')  && !String.isBlank(smap.get('person_account_id')) &&
                    smap.containsKey('contact_id')  && !String.isBlank(smap.get('contact_id')) ) {
            List<Master_Contact__c> masterContacts = [select
                                        Id,
                                        Name,
                                        Contact__c,
                                        Person_Account__c
                                    from
                                        Master_Contact__c
                                    where
                                        Person_Account__c = :smap.get('person_account_id')
                                    and Contact__c = :smap.get('contact_id')];
           if (masterContacts.size() > 0) {
                response.code = 200;
                response.result = masterContacts;
            } else {
                System.debug('No Master Contact found');
                response.code = 404;
                response.result = 'No Master Contact found';
            }
        } else if (smap.containsKey('person_account_id')  && !String.isBlank(smap.get('person_account_id'))) {
            List<Master_Contact__c> masterContacts = [select
                                        Id,
                                        Name,
                                        Contact__c,
                                        Person_Account__c
                                    from
                                        Master_Contact__c
                                    where
                                        Person_Account__c = :smap.get('person_account_id')];
           if (masterContacts.size() > 0) {
                response.code = 200;
                response.result = masterContacts;
            } else {
                System.debug('No Master Contact found');
                response.code = 404;
                response.result = 'No Master Contact found';
            }
        } else if (smap.containsKey('contact_id')  && !String.isBlank(smap.get('contact_id'))) {
            List<Master_Contact__c> masterContacts = [select
                                        Id,
                                        Name,
                                        Contact__c,
                                        Person_Account__c
                                    from
                                        Master_Contact__c
                                    where
                                        Contact__c = :smap.get('contact_id')];
           if (masterContacts.size() > 0) {
                response.code = 200;
                response.result = masterContacts;
            } else {
                System.debug('No Master Contact found');
                response.code = 404;
                response.result = 'No Master Contact found';
            }
        }

        SystemLogUtil.info(MasterContactRestResource.class.toString(), '"findMasterContact" response', String.valueOf(response));

        return JSON.serialize(response);
    }
}