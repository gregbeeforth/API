/**
 * Rest API that takes an email address and course id
 * then creates an opportunity for the contact with the email address and course id
 *
 * @author Jon Kenny, John Au (Trineo)
 **/
@RestResource(urlMapping='/Contact')
global with sharing class ContactRestResource {

    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';

    global static final String FIRST_NAME_PARAM = 'first_name';
    global static final String LAST_NAME_PARAM = 'last_name';
    global static final String EMAIL_PARAM = 'email';
    global static final STring TITLE_PARAM = 'title';
    global static final String EMAIL_VERIFIED_PARAM = 'email_verified';
    global static final String WORK_EMAIL_PARAM = 'work_email';
    global static final String WORK_VERIFIED_PARAM = 'work_verified';
    global static final String TERMS_PARAM = 'terms';
    global static final String SP_PARAM = 'sp_id';

    global static final String ADDRESS_STREET_PARAM = 'street';
    global static final String ADDRESS_SUBURB_PARAM = 'suburb';
    global static final String ADDRESS_STATE_PARAM = 'state';
    global static final String ADDRESS_POSTCODE_PARAM = 'postcode';
    global static final String ADDRESS_COUNTRY_PARAM = 'country';

    global static final String MOBILE_PARAM = 'mobile';
    global static final String DOB_PARAM = 'dob';

    global static final String COMPANY_NAME_PARAM = 'company_name';
    global static final String COMPANY_ID_PARAM = 'company_id';
    global static final String ABN_PARAM = 'abn';
    global static final String NEWSLETTER_SUBSCRIPTIONS_PARAM = 'newsletter_subscriptions';

    global static final String CONTACT_ID_PARAM = 'contact_id';

    global static final String AMI_MEMBERSHIP_NUMBER_PARAM = 'ami_membership_number';

    global static final String MARKETING_TAGGING_PARAM = 'tagging';

    //quiz fields

    global static final String QUIZ_GENDER_PARAM = 'quiz_gender';
    global static final String QUIZ_INDUSTRY_PARAM = 'quiz_industry';
    global static final String QUIZ_LEVEL_EXPERTISE_PARAM = 'quiz_level_expertise';
    global static final String QUIZ_POSTCODE_PARAM = 'quiz_postcode';
    global static final String QUIZ_AREA_OF_EXPERTISE_PARAM = 'quiz_area_expertise';
    global static final String QUIZ_SOURCE_PARAM = 'quiz_source';

    global static final Set<String> subscriptions = new Set<String>{'News__c', 'Awards__c', 'Events__c', 'Education__c',
                                'Compliance__c', 'Member_Activities__c', 'Special_Offers__c'};

    global class ResponseJSON {

        global Object result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() {

        }
    }

    @HttpPost
    global static String createContact() {
        SystemLogUtil.info(ContactRestResource.class.toString(), '"createContact" called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            String firstName = parameters.get(FIRST_NAME_PARAM);
            String lastName = parameters.get(LAST_NAME_PARAM);
            String email = parameters.get(EMAIL_PARAM);
            String emailVerified = parameters.get(EMAIL_VERIFIED_PARAM);
            String workEmail = parameters.get(WORK_EMAIL_PARAM);
            String workVerified = parameters.get(WORK_VERIFIED_PARAM);
            String mobile = parameters.get(MOBILE_PARAM);
            String dob = parameters.get(DOB_PARAM);
            String title = parameters.get(TITLE_PARAM);
            String terms = parameters.get(TERMS_PARAM);
            String spForm = parameters.get(SP_PARAM);

            String street = parameters.get(ADDRESS_STREET_PARAM);
            String suburb = parameters.get(ADDRESS_SUBURB_PARAM);
            String state = parameters.get(ADDRESS_STATE_PARAM);
            String postcode = parameters.get(ADDRESS_POSTCODE_PARAM);
            String country = parameters.get(ADDRESS_COUNTRY_PARAM);

            String companyName = parameters.get(COMPANY_NAME_PARAM);
            String companyId = parameters.get(COMPANY_ID_PARAM);
            String abn = parameters.get(ABN_PARAM);
            String newsletterSubscriptions = parameters.get(NEWSLETTER_SUBSCRIPTIONS_PARAM); //to be JSON decoded

            String contactId = parameters.get(CONTACT_ID_PARAM);

            String amiMembershipNumber = parameters.get(AMI_MEMBERSHIP_NUMBER_PARAM);

            String marketingTagging = parameters.get(MARKETING_TAGGING_PARAM);

            String quizGender = parameters.get(QUIZ_GENDER_PARAM);
            String quizIndustry = parameters.get(QUIZ_INDUSTRY_PARAM);
            String quizLevelExpertise = parameters.get(QUIZ_LEVEL_EXPERTISE_PARAM);
            String quizPostcode = parameters.get(QUIZ_POSTCODE_PARAM);
            String quizAreaOfExerptise = parameters.get(QUIZ_AREA_OF_EXPERTISE_PARAM);
            String quizSource = parameters.get(QUIZ_SOURCE_PARAM);

            Boolean isUpdate = !String.isBlank(contactId);

            String error = '';

            Contact c = new Contact();

            if (isUpdate) {
                try {
                    c = [Select Id From Contact Where Id = :contactId];
                } catch (Exception e) {
                    System.debug(e);
                    error += 'Invalid Contact ID: ' + contactId + '. Error attempting to retrieve Contact record';
                    response.error = error;
                    response.code = 500;

                    return JSON.serialize(response);
                }
            }

            if (!String.isBlank(title)) {
                c.Title = title;
            }

            if (!String.isBlank(firstName)) {
                c.FirstName = firstName;
            }

            if (!String.isBlank(dob)) {
                try {
                    String[] datelist = dob.split('/');
                    String dd = datelist[0];
                    String mm = datelist[1];
                    String yyyy = datelist[2];
                    c.Birthdate = Date.valueOf(yyyy + '-' + mm + '-' + dd + ' 00:00:00');
                } catch (Exception e) {
                    error += 'Error with dob.  Format should be dd/mm/yyyy';
                }
            }

            if (String.isBlank(lastName)) {
                error += FIELD_MISSING_RESPONSE + LAST_NAME_PARAM + '\n';
            } else {
                c.LastName = lastName;
            }

            if (String.isBlank(email)) {
                error += FIELD_MISSING_RESPONSE + EMAIL_PARAM + '\n';
            } else {
                c.Email = email;
            }

            if (String.isBlank(emailVerified)) {
                //error += FIELD_MISSING_RESPONSE + EMAIL_VERIFIED_PARAM + '\n';
            } else {
                c.Email_Invalid__c = !Boolean.valueOf(emailVerified);
            }

            if (String.isBlank(street)) {
                //error += FIELD_MISSING_RESPONSE + ADDRESS_STREET_PARAM + '\n';
            } else {
                c.MailingStreet = street;
            }

            if (String.isBlank(suburb)) {
                //error += FIELD_MISSING_RESPONSE + ADDRESS_SUBURB_PARAM + '\n';
            } else {
                c.MailingCity = suburb;
            }

            if (String.isBlank(state)) {
                //error += FIELD_MISSING_RESPONSE + ADDRESS_STATE_PARAM + '\n';
            } else {
                c.MailingStateCode = state;
            }

            if (String.isBlank(postcode)) {
                //error += FIELD_MISSING_RESPONSE + ADDRESS_POSTCODE_PARAM + '\n';
            } else {
                c.MailingPostalCode = postcode;
            }

            if (String.isBlank(country)) {
                //error += FIELD_MISSING_RESPONSE + ADDRESS_COUNTRY_PARAM + '\n';
            } else {
                c.MailingCountryCode = getCountryCode(country);
            }

            if (String.isBlank(newsletterSubscriptions)) {
                //error += FIELD_MISSING_RESPONSE + NEWSLETTER_SUBSCRIPTIONS_PARAM + '\n';
            } else {
                parseNewsletterSubscriptions(c, newsletterSubscriptions);
            }

            if (!String.isBlank(mobile)) {
                c.MobilePhone = mobile;
            }

            if (!String.isBlank(terms)) {
                if (terms == 'true') {
                    c.Terms_Conditions__c = true;
                } else {
                    c.Terms_Conditions__c = false;
                }
            }

            if (!String.isBlank(spForm)) {
                c.SP_Forms_ID__c = spForm;
            }

            if (!String.isBlank(quizGender)) {
                c.Quiz_Gender__c = quizGender;
            }

            if (!String.isBlank(quizIndustry)) {
                c.Quiz_Industry__c = quizIndustry;
            }

            if (!String.isBlank(quizLevelExpertise)) {
                c.Quiz_Level_Expertise__c = quizLevelExpertise;
            }

            if (!String.isBlank(quizPostcode)) {
                c.Quiz_Postcode__c = quizPostcode;
            }

            if (!String.isBlank(quizAreaOfExerptise)) {
                c.Quiz_Area_of_expertise__c = quizAreaOfExerptise;
            }

            if (!String.isBlank(quizSource)) {
                c.Quiz_Source__c = quizSource;
            }

            if (!String.isBlank(amiMembershipNumber)) {
                c.Ami_Membership_Number__c = Integer.valueOf(amiMembershipNumber);
            }

            if (!String.isBlank(marketingTagging)) {
                c.Marketing_Tagging__c = marketingTagging;
            }

            if (!String.isBlank(companyId)) {
                //Check to see account exists
                List<Account> a = [Select Id From Account Where Id = :companyId];
                if (a.size()>0){
                    c.AccountId = companyId;  
                }        
            }

            //not an 'update' and missing a required field- don't insert the contact and chuck an error
            if (!String.isBlank(error) && !isUpdate) {
                response.error = error;
                response.code = 500;

                return JSON.serialize(response);
            }

            if (!isUpdate) {
                Id contactRecordType = Schema.SObjectType.Contact.RecordTypeInfosByName.get('Business').RecordTypeId;
                c.RecordTypeId = contactRecordType;
                c.Terms_Conditions__c = true;

                insert (c);
            } else {
                update (c);
            }

            response.result = c.Id;
            response.code = 200;
        } catch (Exception e) {
            response.error = UNEXPECTED_EXCEPTION + e.getMessage();
            response.code = 500;
        }

        SystemLogUtil.info(ContactRestResource.class.toString(), '"createContact" response', String.valueOf(response));

        return JSON.serialize(response);
    }


    /**
     * API that takes a contact id and returns details for the matching contact record
     **/
    @HttpGet
    global static String findContact() {
        SystemLogUtil.info(ContactRestResource.class.toString(), '"findContact" called', String.valueOf(RestContext.request));

        ResponseJSON response = new ResponseJSON(); //to be returned

        RestRequest rr = RestContext.request;
        Map<String, String> smap = rr.params;

        if (smap.containsKey('id')  && !String.isBlank(smap.get('id'))) {
            List<Contact> contacts = [select
                                        id,
                                        firstname,
                                        lastname,
                                        email,
                                        Email_Invalid__c,
                                        Secondary_Email__c,
                                        Status__c,
                                        MailingStreet,
                                        MailingCity,
                                        MailingState,
                                        MailingPostalCode,
                                        MailingCountry,
                                        Account.Name,
                                        AccountId,
                                        eNewsletter__c,
                                        title,
                                        BirthDate,
                                        MobilePhone,
                                        News__c,
                                        Awards__c,
                                        Events__c,
                                        Education__c,
                                        Compliance__c,
                                        Member_Activities__c,
                                        Special_Offers__c,
                                        SP_Forms_ID__c,
                                        Terms_Conditions__c
                                    from
                                        contact
                                    where
                                        id = :smap.get('id')];
            if (contacts.size() > 0) {
                response.code = 200;
                response.result = contacts;
            } else {
                System.debug('No contact found');
                response.code = 404;
                response.result = 'No contact found';
            }
        } else if (smap.containsKey('email')  && !String.isBlank(smap.get('email'))) {
            List<Contact> contacts = [select
                                        id,
                                        firstname,
                                        lastname,
                                        email,
                                        Email_Invalid__c,
                                        Secondary_Email__c,
                                        Status__c,
                                        MailingStreet,
                                        MailingCity,
                                        MailingState,
                                        MailingPostalCode,
                                        MailingCountry,
                                        Account.Name,
                                        AccountId,
                                        eNewsletter__c,
                                        title,
                                        BirthDate,
                                        MobilePhone,
                                        News__c,
                                        Awards__c,
                                        Events__c,
                                        Education__c,
                                        Compliance__c,
                                        Member_Activities__c,
                                        Special_Offers__c,
                                        SP_Forms_ID__c,
                                        Terms_Conditions__c
                                    from
                                        contact
                                    where
                                        email = :smap.get('email')];
            if (contacts.size() > 0) {
                response.code = 200;
                response.result = contacts;
            } else {
                System.debug('No contact found');
                response.code = 404;
                response.result = 'No contact found';
            }
        }

        SystemLogUtil.info(ContactRestResource.class.toString(), '"findContact" response', String.valueOf(response));

        return JSON.serialize(response);
    }

    private static void parseNewsletterSubscriptions(Contact c, String newsletterSubscriptionJSON) {
        List<Object> newsletterSubscriptions = (List<Object>) JSON.deserializeUntyped(newsletterSubscriptionJSON);
        Set<String> userSubscriptions = new Set<String>();

        for (Object o: newsletterSubscriptions) {
            userSubscriptions.add((String) o);
        }

        for(String s: subscriptions) {
            if (userSubscriptions.contains(s)) {
                c.put(s,true);
            } else {
                c.put(s,false);
            }
        }

        //for (Object o : newsletterSubscriptions) {
        //    try {
        //        if(subscriptions.contains((String) o))
        //        c.put((String) o, true);
        //    } catch (Exception e) {
        //        System.debug(e);
        //    }
        //}
    }

    private static String getCountryCode(String countryName) {
        String countryCode = '';

        Map<String, String> countryMap = New Map<String, String>();
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
            countryMap.put(f.getLabel(), f.getValue());
        }

        if(countryMap.containsKey(countryName)) {
            countryCode = countryMap.get(countryName);
        }
        return countryCode;
    }
}