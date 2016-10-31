/**
 * Tests for CourseRestResource.cls
 *
 * @author Jon Kenny, John Au (Trineo)
 */
@IsTest
private class CourseRestResourceTest {
    //Create default LMS Setting.
    @testSetup static void setup() {

        Xero_Setting__c xeroSetting = TestObjectFactory.getXeroSettings('AU', 'privateKey', '123456789', 'consumerSecret', true);
        
        LMS_Settings__c defaultSetting = new LMS_Settings__c();
        defaultSetting.Name = 'Default';
        defaultSetting.Endpoint__c = 'http://adma-sb.ecampus.com.au/api2.php?';
        defaultSetting.Token__c = '8dLkuB6CQKHLCCeFwUFwLqz5AmQ2mw';
        insert defaultSetting;
    }    


    /**
     * Tests response when 'emailAddress' parameter is missing
     */
    @IsTest
    private static void testInvalidEmail() {
        RestRequest restRequest = new RestRequest();

        restRequest.addParameter('courseId', '42');

        RestContext.request = restRequest;

        Test.setMock(HttpCalloutMock.class, new CourseRestResourceCalloutMock());

        Test.startTest();

        String result = CourseRestResource.buyCourse();

        Test.stopTest();

        System.assertEquals(CourseRestResource.MISSING_EMAIL_RESPONSE, result);
    }

    /**
     * Tests response when 'courseId' parameter is missing
     */
    @IsTest
    private static void testNoCourseId() {
        RestRequest restRequest = new RestRequest();

        restRequest.addParameter('emailAddress', 'testmctest@test.com');

        RestContext.request = restRequest;

        Test.setMock(HttpCalloutMock.class, new CourseRestResourceCalloutMock());

        Test.startTest();

        String result = CourseRestResource.buyCourse();

        Test.stopTest();

        System.assertEquals(CourseRestResource.NO_COURSE_ID_RESPONSE, result);
    }

    /**
     * Tests response when no Contact is found in Salesforce for the provided email address
     */
    @IsTest
    private static void testNoContactFound() {
        RestRequest restRequest = new RestRequest();

        restRequest.addParameter('emailAddress', 'testmctest@test.com');
        restRequest.addParameter('courseId', '42');

        RestContext.request = restRequest;

        Test.setMock(HttpCalloutMock.class, new CourseRestResourceCalloutMock());

        Test.startTest();

        String result = CourseRestResource.buyCourse();

        Test.stopTest();

        System.assertEquals(CourseRestResource.NO_CONTACT_FOUND_RESPONSE + 'testmctest@test.com', result);
    }

    /**
     * Tests response/result when we fail to register the user on the LMS-
     * this will result in a Course with the Status__c of 'Not registered'
     *
     * (CourseRestResource will return successfully- but this is because we have to run the callout to the LMS in an @future)
     */
    @IsTest
    private static void testLMSEndpointFailure() {
        RestRequest restRequest = new RestRequest();

        restRequest.addParameter('emailAddress', 'testmctest@test.com');
        restRequest.addParameter('courseId', '42');

        RestContext.request = restRequest;

        Account testAccount = new Account(Name = 'Test Account');

        insert (testAccount);

        Contact testContact = new Contact(LastName = 'McTest', Email = 'testmctest@test.com', AccountId = testAccount.Id, Terms_Conditions__c = true);

        insert (testContact);

        Test.setMock(HttpCalloutMock.class, new CourseRestResourceCalloutMock(false));

        Test.startTest();

        String result = CourseRestResource.buyCourse();

        Test.stopTest();

        System.assertEquals(CourseRestResource.SUCCESS_RESPONSE, result);

        List<Course__c> insertedCourses = [Select Status__c From Course__c];

        System.assertEquals(1, insertedCourses.size());
        System.assertEquals('Not registered', insertedCourses[0].Status__c);
    }

    /**
     * Tests a 'successful' call to CourseRestResource- which results in the creation of a 'Registered' Course__c object,
     * and an Opportunity linked to the Account/Course__c
     */
    @IsTest
    private static void testSuccess() {
        RestRequest restRequest = new RestRequest();

        restRequest.addParameter('emailAddress', 'testmctest@test.com');
        restRequest.addParameter('courseId', '42');

        RestContext.request = restRequest;

        Account testAccount = new Account(Name = 'Test Account');

        insert (testAccount);

        Contact testContact = new Contact(LastName = 'McTest', Email = 'testmctest@test.com', AccountId = testAccount.Id, Terms_Conditions__c = true);

        insert (testContact);

        Test.setMock(HttpCalloutMock.class, new CourseRestResourceCalloutMock());

        Test.startTest();

        String result = CourseRestResource.buyCourse();

        Test.stopTest();

        List<Course__c> insertedCourses = [Select Status__c, LMS_Id__c From Course__c];

        System.assertEquals(CourseRestResource.SUCCESS_RESPONSE, result);
        System.assertEquals(1, insertedCourses.size());
        System.assertEquals('Registered', insertedCourses[0].Status__c);
        System.assertEquals('42', insertedCourses[0].LMS_Id__c);

        List<Opportunity> insertedOpportunities = [Select Id From Opportunity Where Course_Id__c = :insertedCourses[0].LMS_Id__c And AccountId = :testAccount.Id];

        System.assertEquals(1, insertedOpportunities.size());
    }

    public class CourseRestResourceCalloutMock implements HttpCalloutMock {

        private Boolean respondWithSuccess = true;

        public String resultString = '<xml><status>ok</status></xml>';
        public String errorString = '<xml><status>error</status><message>Assignment already exists</message></xml>';
        public String errorString2 = '<xml><status>error</status><message>User does not exist</message></xml>';
        public String errorString3 = '<xml><status>error</status><message>Course doesn\'t exist</message></xml>';

        public CourseRestResourceCalloutMock() {

        }

        public CourseRestResourceCalloutMock(Boolean respondWithSuccess) {
            this.respondWithSuccess = respondWithSuccess;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(200);
            resp.setStatus('ok');

            if (respondWithSuccess) {
                resp.setBody(resultString);
            } else {
                resp.setbody(errorString3); //pick a random error string
            }

            return resp;
        }
    }

}