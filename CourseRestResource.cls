/**
 * Rest API that takes an email address and course id
 * then creates an opportunity for the contact with the email address and course id
 *
 * @author Jon Kenny, John Au (Trineo)
 **/
@RestResource (urlMapping='/Course')
global with sharing class CourseRestResource {

    private static final String FAILED_REGISTRATION_STATUS = 'Registration Failed';

    global static final String SUCCESS_RESPONSE = 'Success';
    global static final String NO_COURSE_ID_RESPONSE = 'No course ID specified';
    global static final String USER_ALREADY_REGISTERED_RESPONSE = 'User already registered for course';
    global static final String NO_CONTACT_FOUND_RESPONSE = 'No contact found with address ';
    global static final String MISSING_EMAIL_RESPONSE = 'Missing email address';

    @HttpPost
    global static String buyCourse() {
        SystemLogUtil.info(CourseRestResource.class.toString(), '"buyCourse" called', String.valueOf(RestContext.request) + JSON.serialize(RestContext.request.params));

        RestRequest rr = RestContext.request;
        Map<String, String> smap = rr.params;
        String courseId;
        String response;

        if (!smap.containsKey('courseId') || String.isBlank(smap.get('courseId'))) {
            response = NO_COURSE_ID_RESPONSE;
        } else {
            courseId = smap.get('courseId');
        }

        if (!String.isBlank(courseId)) {
            if (smap.containsKey('emailAddress')  && !String.isBlank(smap.get('emailAddress'))) {
                List<Contact> contacts = [Select Id, AccountId, Email, FirstName, LastName From Contact Where Email = :smap.get('emailAddress')];
                if (contacts.size() > 0) {
                    //assume email address is unique, just use the first contact
                    Contact contact = contacts[0];
                    Course__c course = getCourse(contact.Id, courseId);

                    //check if course has already been created for the contact
                    if (course != null) {
                        if (course.Status__c != FAILED_REGISTRATION_STATUS) {
                            response = USER_ALREADY_REGISTERED_RESPONSE;
                        } else {
                            //use existing course
                        }
                    } else {
                        Opportunity opportunity = createOpportunity(courseId, contact.AccountId);
                        course = createCourse(contact.Id, courseId, opportunity.Id);
                    }

                    if (response != USER_ALREADY_REGISTERED_RESPONSE) {
                        // callout to LMS to register course
                        createUserAndRegisterCourse(contact.Email, contact.FirstName, contact.LastName, contact.Id, courseId, course.Id);

                        response = SUCCESS_RESPONSE;
                    }
                } else {
                    response = NO_CONTACT_FOUND_RESPONSE + smap.get('emailAddress');
                }
            } else {
                response = MISSING_EMAIL_RESPONSE;
            }
        }

        SystemLogUtil.info(CourseRestResource.class.toString(), '"buyCourse" response', response);

        return response;
    }

    /**
     * Create a user on the LMS from a Contact object
     **/
    @future(callout=true)
    public static void createUserAndRegisterCourse(String emailAddress, String firstName, String lastName, String contactId, String courseId, String courseSfId) {
        try {
            //Getting LMS default settings.
            LMS_Settings__c defaultSettings = getLMSSettings();

            // create the user on the LMS
            HttpRequest req = new HttpRequest();
            String parameters = 'token='+defaultSettings.Token__c;
            parameters += '&action=create_user';
            parameters += '&login=' + emailAddress;
            parameters += '&password=test';
            parameters += '&email=' + emailAddress;
            parameters += '&name=' + firstName;
            parameters += '&surname=' + lastName;
            parameters += '&languages=english';
            req.setEndpoint(defaultSettings.Endpoint__c + parameters);
            req.setMethod('GET');
            Http h = new Http();

            HttpResponse res = h.send(req);
            System.debug(res.getBody());

            if ((res.getStatusCode() == 200 && res.getBody().contains('ok'))
                || res.getBody().contains('User already exists')) {
                // register the user for a course
                Boolean registeredOnLMS = registerForCourse(emailAddress, courseId);

                if (registeredOnLMS) {
                    updateCourseStatus(courseSfId, 'Registered');
                } else {
                    updateCourseStatus(courseSfId, FAILED_REGISTRATION_STATUS);
                }
            }

            SystemLogUtil.info(CourseRestResource.class.toString(), '"createUserAndRegisterCourse" request', String.valueOf(req));
            SystemLogUtil.info(CourseRestResource.class.toString(), '"createUserAndRegisterCourse" response', String.valueOf(res));
        } catch (Exception e) {
            SystemLogUtil.error(CourseRestResource.class.toString(), '"createUserAndRegisterCourse" fatal', String.valueOf(e));
        }
        // needs an else block if user registration fails?
    }

    //second callout to LMS to register the user for a course
    private static Boolean registerForCourse(String emailAddress, String courseId) {
        //Getting LMS default settings.
        LMS_Settings__c defaultSettings = getLMSSettings();

        HttpRequest req = new HttpRequest();
        String parameters = 'token='+defaultSettings.Token__c;
        parameters += '&action=course_to_user';
        parameters += '&login=' + emailAddress;
        //parameters += '&password=test';
        parameters += '&course=' + courseId;
        parameters += '&type=student';
        req.setEndpoint(defaultSettings.Endpoint__c + parameters);
        System.debug(req.getEndpoint());
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug(res.getBody());

        SystemLogUtil.info(CourseRestResource.class.toString(), '"registerForCourse" request', String.valueOf(req));
        SystemLogUtil.info(CourseRestResource.class.toString(), '"registerForCourse" request', String.valueOf(res));

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
     * Check if Course__c object exists for the contactId/courseId combo
     */
    private static Course__c getCourse(String contactId, String courseId) {
        List<Course__c> courses = [Select Id, Status__c From Course__c Where Contact__c = :contactId And LMS_Id__c = :courseId];

        return courses.isEmpty() ? null : courses[0];
    }

    /**
     * Returns opportunity if it exists, otherwise creates it
     */
    private static Opportunity createOpportunity(String courseId, String contactAccountId) {
        List<Opportunity> opportunities = [Select Id From Opportunity Where Course_Id__c = :courseId And AccountId = :contactAccountId];
        Opportunity opportunity;

        if (opportunities.isEmpty()) {
            opportunity = new Opportunity();

            opportunity.Course_Id__c = courseId;
            opportunity.AccountId = contactAccountId;
            opportunity.StageName = 'Closed Won';
            opportunity.CloseDate = Date.today();
            opportunity.Name = 'Course ' + courseId;

            insert (opportunity);
        } else {
            opportunity = opportunities[0];
        }

        return opportunity;
    }

    /**
     * Creates a Course__c object for the contactId/courseId combo
     */
    private static Course__c createCourse(Id contactId, String courseId, String opportunityId) {
        Course__c course = new Course__c();

        course.Contact__c = contactId;
        course.LMS_Id__c = courseId;
        course.Opportunity__c = opportunityId;
        course.Status__c = 'Not registered';

        insert (course);

        return course;
    }

    /**
     * Updates status on an existing Course__c object
     */
    private static void updateCourseStatus(Id courseSfId, String status) {
        Course__c course = [Select Id From Course__c Where Id = :courseSfId];

        course.Status__c = status;

        update (course);
    }




}