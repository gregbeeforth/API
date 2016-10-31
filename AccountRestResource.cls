@RestResource (urlMapping='/Accounts')
global with sharing class AccountRestResource {

    global class ResponseJSON {

        global Object result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() {

        }
    }
	
	/**
	 * API that accepts a string containing a domain and returns any accounts where the domain__c field contains
	 * the domain
	 **/

	@HttpGet
	global static List<Account> findAccount() {
		RestRequest rr = RestContext.request;
		Map<String, String> smap = rr.params;
		RestResponse res = RestContext.response;

		SystemLogUtil.info(AccountRestResource.class.toString(), '"findAccount" called', String.valueOf(RestContext.request));

		String queryString = 'select id, name, PersonContactId, Member_Status__c, ADMA_Member__c, domain__c, Members_Type__c, Industry, BillingAddress, Website, Type, Phone, Trading_As__c, No_of_Employees__c, RecordType.Name from account '; 
		if (smap.containsKey('domain')  && !String.isBlank(smap.get('domain'))) {
			queryString +=	'where domain__c like \'%' + smap.get('domain') +  '%\'';
		}
		else if (smap.containsKey('id')  && !String.isBlank(smap.get('id'))) {
			queryString +=	'where Id = \'' + smap.get('id') +  '\'';
		}
		else if (smap.containsKey('search')  && !String.isBlank(smap.get('search'))) {
			queryString +=	'where name like \'%' + smap.get('search') +  '%\'';
		}
		//Person Accounts
		else if (smap.containsKey('email')  && !String.isBlank(smap.get('email'))) {
			queryString +=	'where isPersonAccount = true and PersonEmail = \'' + smap.get('email') +  '\'';
		}
		else {
			queryString +=	'where ADMA_Member__c = true';
		}
	
		System.debug(queryString);
		List<Account> accounts = Database.query(queryString);

		//Remove non-exact domain matches: this fuctionality should really sit with the calling application - but due to resource constraints is done here to fix Prod issue.
		List<Account> exactaccounts = new List<Account>();
		List<Account> returnedaccounts = new List<Account>();

		if (smap.containsKey('domain')  && !String.isBlank(smap.get('domain'))){
			
			for (Account exactaccount: accounts){
				//Does account have multiple domains
				if (exactaccount.domain__c.containsAny(',') || exactaccount.domain__c.containsAny(';')){
					List<String> domains = new List<String>();
					if (exactaccount.domain__c.contains(',')){				
						domains = exactaccount.domain__c.split(',');
					}
					if (exactaccount.domain__c.contains(';')){				
						domains = exactaccount.domain__c.split(';');
					}
					if (domains.size()>0){
						for (String domain: domains){
							if(domain.deleteWhitespace().equalsIgnoreCase(smap.get('domain'))){
								exactaccounts.add(exactaccount);
								break;
							}
						}
					}
				}
				//Single domain
				else {
					if(exactaccount.domain__c.equalsIgnoreCase(smap.get('domain'))){
						exactaccounts.add(exactaccount);
					}
				}				
			}
			//Return Member only if present
			for (Account memberaccount: exactaccounts){
				if (memberaccount.RecordType.Name == 'Member'){
					returnedaccounts.add(memberaccount);
				}
			}
			//Return non-member if member not present
			if (returnedaccounts.size() == 0){
				for (Account assocmemberaccount: exactaccounts){
					if (assocmemberaccount.RecordType.Name == 'Associate / Subsidiary Member'){
						returnedaccounts.add(assocmemberaccount);
					}
				}
			}
			//Return All
			if (returnedaccounts.size() == 0){
				for (Account remainingaccount: exactaccounts){
						returnedaccounts.add(remainingaccount);
				}
			}
		}

		if(!Test.isRunningTest()){
			if (smap.containsKey('domain')  && !String.isBlank(smap.get('domain'))) {
				if (returnedaccounts.size() > 0) {
					res.statusCode= 200;
					res.responseBody = Blob.valueOf(JSON.serialize(returnedaccounts));
				}
				else {
					System.debug('No account found');
					res.statusCode = 404;
					res.responseBody = Blob.valueOf('No account found');
				}
			}
			else{
				if (accounts.size() > 0) {
					res.statusCode= 200;
					res.responseBody = Blob.valueOf(JSON.serialize(accounts));
				}
				else {
					System.debug('No account found');
					res.statusCode = 404;
					res.responseBody = Blob.valueOf('No account found');
				}
			}
		}

		if (smap.containsKey('domain')  && !String.isBlank(smap.get('domain'))) {
			SystemLogUtil.info(AccountRestResource.class.toString(), '"findAccount" response', String.valueOf(returnedaccounts));
			return returnedaccounts;	
		}
		else {
			SystemLogUtil.info(AccountRestResource.class.toString(), '"findAccount" response', String.valueOf(accounts));
			return accounts;
		}
	}

	@HttpPost
	global static String createAccount() {
        ResponseJSON response = new ResponseJSON(); //to be returned
		
		try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            SystemLogUtil.info(AccountRestResource.class.toString(), '"createAccount" called', String.valueOf(RestContext.request));

            String CompanyName	= parameters.get('name');
            String LastName	= parameters.get('lastname');
            String FirstName = parameters.get('firstname');
			String Website = parameters.get('website');
			String Type = parameters.get('type');
			String Domain = parameters.get('domain');
			String Industry = parameters.get('industry');
			String AccountId = parameters.get('id');
			String PrimaryContact = parameters.get('contact');
			String ReasonEnquiry = parameters.get('reason');
			String NumberEmployees = parameters.get('employees');
			String Email = parameters.get('email');
			String Phone = parameters.get('phone');
			String ContactMethod = parameters.get('contactmethod');
			String Revenue = parameters.get('revenue');
			String MembershipLevel = parameters.get('membership');
			Boolean isPersonAccount = false;
			if (parameters.containsKey('personflag')  && !String.isBlank(parameters.get('personflag'))){
				isPersonAccount = Boolean.valueof(parameters.get('personflag'));
			}

			Boolean isUpdate = !String.isBlank(AccountId);

			String error = '';
			Account a = new Account();

            if (isUpdate) {
                try {
                    a = [Select Id From Account Where Id = :accountId];
                } catch (Exception e) {
                    System.debug(e);
                    error += 'Invalid Account ID: ' + accountId + '. Error attempting to retrieve Account record';
                    response.error = error;
                    response.code = 500;
                    return JSON.serialize(response);
                }
            }
			
			if (isPersonAccount != true) {

				if (!String.isBlank(CompanyName)) {
					a.Name = CompanyName;
				} else {
					error += 'Missing Company Name \n';
				}

				if (!String.isBlank(Website)) {
					a.Website = Website;
				} else {
					error += 'Missing URL \n';
				}
				
				if (!String.isBlank(domain)) {
					a.domain__c = Domain;
				} else {
					error += 'Missing Domain \n';
				}
			}
			else {

				if (!String.isBlank(LastName)) {
					a.LastName = LastName;
				} else {
					error += 'Missing Last Name \n';
				}

				if (!String.isBlank(FirstName)) {
					a.FirstName = FirstName;
				} else {
					error += 'Missing First Name \n';
				}				
			}
			
			if (!String.isBlank(type)) {
				a.Type = Type;
			} 
			
			if (!String.isBlank(Industry)) {
				a.Industry = Industry;
			} 

			if (!String.isBlank(PrimaryContact)) {
				a.Primary_Contact__c = PrimaryContact;
			}

			if (!String.isBlank(ReasonEnquiry)) {
				a.Reason_for_Enquiry__c = ReasonEnquiry;
			}

			if (!String.isBlank(NumberEmployees)) {
				a.No_of_Employees__c = NumberEmployees;
			}

			if (!String.isBlank(Email)) {
				a.Accounts_Email__c = Email;
			}

			if (!String.isBlank(Phone)) {
				a.Phone = Phone;
			}

			if (!String.isBlank(ContactMethod)) {
				a.Preferred_contact_method__c = ContactMethod;
			}
			
			if (!String.isBlank(Revenue)) {
				a.Annual_Revenue__c = Revenue;
			}

			if (!String.isBlank(MembershipLevel)) {
				a.Membership_level__c = MembershipLevel;
			}


			//not an 'update' and missing a required field- don't insert the contact and chuck an error
            if (!String.isBlank(error) && !isUpdate) {
                response.error = error;
                response.code = 500;

                return JSON.serialize(response);
            } else {
				if (!isUpdate) {
	                if (isPersonAccount != true) {
		                Id accountRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Non-Member').RecordTypeId;
		                a.RecordTypeId = accountRecordType;
	            	}
	            	else {
	            		Id personRecordType = Schema.SObjectType.Account.RecordTypeInfosByName.get('Person Account').RecordTypeId;
		                a.RecordTypeId = personRecordType;	
	            	}
	                insert (a);
	            } else {
	                update (a);
	            }

	            if (isPersonAccount != true){
	            	response.result = a.Id;
	            }
	            else {
	            	//Need to requery as PersonContactId is not populated yet. PersonContactId is returned as the ContactId is used to create the Opportunity.
	            	response.result = [Select Id, PersonContactId From Account Where Id = :a.Id];
	            }  
	            response.code = 200;
            }
        } catch (Exception e) {
            response.error = 'Unexpected Exception: ' + e.getMessage();
            response.error += e;
            response.code = 500;
        }

        SystemLogUtil.info(AccountRestResource.class.toString(), '"createAccount" response', String.valueOf(response));

        return JSON.serialize(response);
	}
}