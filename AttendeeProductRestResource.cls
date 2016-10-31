@RestResource(urlMapping='/CreateAttendeeProduct')
global without sharing class AttendeeProductRestResource {
    global static final String FIELD_MISSING_RESPONSE = 'Required field missing from request: ';
    global static final String INVALID_VALUE_RESPONSE = 'Invalid value: ';
    global static final String UNEXPECTED_EXCEPTION = 'Unexpected Exception: ';
    global static final String SUCCESS = 'Success';

    global static final String FAILED_REGISTRATION_STATUS = 'Registration Failed';

    global static final String CONTACT_ID_PARAM = 'contact_id';
    global static final String PRODUCT_ID_PARAM = 'product_id';
    global static final String MOBILE_NUM_PARAM = 'mobile_num';

    global class ResponseJSON {
        global String result { get; set; }
        global Integer code { get; set; }
        global String error { get; set; }

        global ResponseJSON() { }
    }

    public class DuplicateSignupException extends Exception {

    }

    @HttpPost
    global static String createAttendeeProduct() {
        ResponseJSON response = new ResponseJSON(); //to be returned

        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            Map<String, String> parameters = req.params;

            SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"createAttendeeProduct" request', String.valueOf(req));

            String contact_id = parameters.get(CONTACT_ID_PARAM);
            String opportunityProductId = parameters.get(PRODUCT_ID_PARAM);
            String mobileNum = parameters.get(MOBILE_NUM_PARAM);

            String error = '';
            if (String.isBlank(contact_id)) {
                error += FIELD_MISSING_RESPONSE + CONTACT_ID_PARAM + '\n';
            } else if (String.isBlank(opportunityProductId)) {
                error += FIELD_MISSING_RESPONSE + PRODUCT_ID_PARAM + '\n';
            } /*else if (String.isBlank(mobileNum)) {
                error += FIELD_MISSING_RESPONSE + MOBILE_NUM_PARAM + '\n';
            }*/

            Id attendeeProductId;

            if (!String.isBlank(error)) {
                response.error = error;
                response.code = 500;
            } else {
                OpportunityLineItem oppProduct = [Select Attendee_Product__c, OpportunityId From OpportunityLineItem Where Id = :opportunityProductId];

                if (String.isBlank(oppProduct.Attendee_Product__c)) {
                    Attendee_Product__c attendeeProduct = new Attendee_Product__c();

                    attendeeProduct.Opportunity__c = oppProduct.OpportunityId;
                    insert attendeeProduct;

                    //attendeeProduct = [Select Id from Attendee_Product__c where Id in :attendeeProduct];
                    attendeeProductId = attendeeProduct.Id;

                    oppProduct = new OpportunityLineItem(Id = opportunityProductId);
                    oppProduct.Attendee_Product__c = attendeeProduct.Id;

                    update oppProduct;
                } else {
                    attendeeProductId = oppProduct.Attendee_Product__c;
                }

                //JM 26/02 validation to prevent duplicate signups
                List<Attendee__c> attendees = [Select Id From Attendee__c Where Attendee_Product__c = :attendeeProductId And Contact__c = :contact_id];

                if (attendees.size() > 0) {
                    throw new DuplicateSignupException('Duplicate signup detected, aborting');
                }

                Attendee__c attendee = new Attendee__c();
                attendee.Attendee_Product__c = attendeeProductId;
                attendee.Contact__c = contact_id;
                attendee.Mobile_Number__c = mobileNum;

                insert (attendee);
                response.result = SUCCESS;
                response.code = 200;

                //FIXME assuming that only one attendee product is created per call to this API
                // Determine if call needs to be made to LMS based on LMS Code gainst product. If no code exists then no call out is made.
                OpportunityLineItem opportunityProduct = [Select PricebookEntryId, Product2Id From OpportunityLineItem Where Id = :opportunityProductId];
                Product2 product = [Select LMS_Code__c, Product_Type__c From Product2 Where Id = :opportunityProduct.Product2Id];
                if (!String.isBlank(product.LMS_Code__c)){
                    createUserAndRegisterCourse(contact_id, opportunityProductId, attendeeProductId);
                }
            }
        } catch (Exception e) {
            // Update the response details record with the exception error message
           response.error = UNEXPECTED_EXCEPTION + e.getMessage() + e.getStackTraceString();
           response.code = 500;
        }

        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"createAttendeeProduct" response', String.valueOf(response));

        return JSON.serialize(response);
    }

    /**
     * Create a user on the LMS from a Contact object
     **/
    @future(callout=true)
    public static void createUserAndRegisterCourse(String contactId, String opportunityProductId, String attendeeProductId) {
        Attendee__c attendee;

        try {
            //List<Contact> cs = [Select FirstName, LastName, Email From Contact];
            Contact contact = [Select FirstName, LastName, Email From Contact Where Id = :contactId];
            // Greg B: Note that SOQL queries have to be done again as you cannot pass an sObject into an @future callout
            OpportunityLineItem opportunityProduct = [Select PricebookEntryId, Product2Id From OpportunityLineItem Where Id = :opportunityProductId];
            Product2 product = [Select LMS_Code__c, Product_Type__c From Product2 Where Id = :opportunityProduct.Product2Id];
            // End
            List<Attendee__c> attendees = [Select Id From Attendee__c Where Contact__c = :contactId And Attendee_Product__c = :attendeeProductId Order By CreatedDate Desc Limit 1];

            attendee = attendees[0];

            attendee.Course_Id__c = product.LMS_Code__c;

            //Getting LMS default settings.
            LMS_Settings__c defaultSettings = getLMSSettings();

            // create the user on the LMS
            HttpRequest req = new HttpRequest();
            String parameters = 'token=' + defaultSettings.Token__c;
            parameters += '&action=create_user';
            parameters += '&login=' + contact.Email;
            parameters += '&password=test';
            parameters += '&email=' + contact.Email;
            parameters += '&name=' + contact.FirstName;
            parameters += '&surname=' + contact.LastName;
            parameters += '&languages=english';
            req.setEndpoint(defaultSettings.Endpoint__c + parameters);
            req.setMethod('GET');
            Http h = new Http();

            HttpResponse res = h.send(req);
            System.debug('GREGB: ' + res.getBody());

            if ((res.getStatusCode() == 200 && res.getBody().contains('ok'))
                || res.getBody().contains('User already exists')) {
                // register the user for a course or module
                Boolean registeredOnLMS;
                if (product.Product_Type__c == 'Module') {
                    registeredOnLMS = registerForLesson(contact.Email, product.LMS_Code__c);
                } else {
                    registeredOnLMS = registerForCourse(contact.Email, product.LMS_Code__c);
                }

                if (registeredOnLMS) {
                    updateAttendeeStatus(attendee.Id, 'Registered');
                    //updateCourseStatus(courseSfId, 'Registered');
                } else {
                    updateAttendeeStatus(attendee.Id, FAILED_REGISTRATION_STATUS);
                    //updateCourseStatus(courseSfId, FAILED_REGISTRATION_STATUS);
                }
            }
        } catch (Exception e) {
            SystemLogUtil.error(AttendeeProductRestResource.class.toString(), '"createUserAndRegisterCourse" exception', String.valueOf(e));
        }

        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"createUserAndRegisterCourse" success', String.valueOf(attendee));

        update (attendee);
        // needs an else block if user registration fails?
    }

    //second callout to LMS to register the user for a course
    public static Boolean registerForCourse(String emailAddress, String courseId) {
        //Getting LMS default settings.
        LMS_Settings__c defaultSettings = getLMSSettings();

        HttpRequest req = new HttpRequest();
        String parameters = 'token=' + (Test.isRunningTest() ? 'dummy' : defaultSettings.Token__c);
        parameters += '&action=course_to_user';
        parameters += '&login=' + emailAddress;
        //parameters += '&password=test';
        parameters += '&course=' + courseId;
        parameters += '&type=student';
        req.setEndpoint((Test.isRunningTest() ? 'https://test.com/' : defaultSettings.Endpoint__c) + parameters);
        System.debug(req.getEndpoint());
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug(res.getBody());

        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"registerForCourse" request', String.valueOf(req));
        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"registerForCourse" response', String.valueOf(res) + ' ' + res.getBody());

        return res.getStatusCode() == 200;
    }

    //second callout to LMS to register the user for a module/lesson
    public static Boolean registerForLesson(String emailAddress, String lessonId) {
        //Getting LMS default settings.
        LMS_Settings__c defaultSettings = getLMSSettings();

        HttpRequest req = new HttpRequest();
        String parameters = 'token=' + (Test.isRunningTest() ? 'dummy' : defaultSettings.Token__c);
        parameters += '&action=lesson_to_user';
        parameters += '&login=' + emailAddress;
        //parameters += '&password=test';
        parameters += '&lesson=' + lessonId;
        parameters += '&type=student';
        req.setEndpoint((Test.isRunningTest() ? 'https://test.com/' : defaultSettings.Endpoint__c) + parameters);
        System.debug(req.getEndpoint());
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug(res.getBody());

        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"registerForLesson" request', String.valueOf(req));
        SystemLogUtil.info(AttendeeProductRestResource.class.toString(), '"registerForLesson" response', String.valueOf(res) + ' ' + res.getBody());

        return res.getStatusCode() == 200;
    }

    /**
     * Getting LMS API details
     */
    private static LMS_Settings__c getLMSSettings() {
        LMS_Settings__c defaultSettings = LMS_Settings__c.getInstance('Default');
        system.debug('%defaultSettings:'+defaultSettings);
        return defaultSettings;
    }

    /**
     * Updates status on an existing Course__c object
     */
    private static void updateAttendeeStatus(Id attendeeId, String status) {
        Attendee__c attendee = [Select Id From Attendee__c Where Id = :attendeeId];

        attendee.Status__c = status;

        update (attendee);
    }
}