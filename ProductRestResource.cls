@RestResource (urlMapping='/Products/*')
global with sharing class ProductRestResource {
    
    global static final String PRODUCT_FAMILY_PARAM = 'product_family';
    /**
     * API to return all active courses
     **/
    @httpGet
    global static void getActiveCourses() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        /* Added GregB: 01/04/2016 */
        Map<String, String> parameters = req.params;
        
        String productFamily = parameters.get(PRODUCT_FAMILY_PARAM);

        List<Product2> products = new list<Product2>();
        String queryStr =   'SELECT id, name, IsActive, Points__c, Description, Product_Type__c, Start_Date__c, End_date__c, ' +
                            'Location__c, Total_Number_of_Seats__c, ProductCode, LMS_Code__c, Venue__c, Id_Prod__c, ' +
                            '(select pricebook2.name, UnitPrice, Early_Bird_Price__c, Early_Bird_Price_Start_Date__c, Early_Bird_Price_End_Date__c, ' +
                            'Pre_Sale_Price__c, Pre_Sale_Price_Start_Date__c, Pre_Sale_Price_End_Date__c from PriceBookEntries where pricebook2.name = \'Member\' or pricebook2.name = \'Non Member\') ' +
                            'from product2 ' + 
                            'where id in (select Product2id from pricebookentry where (pricebook2.name = \'Member\' or pricebook2.name = \'Non Member\') and IsActive = true) ' +
                            'and Family = :productFamily and IsActive = true ';

        queryStr +=         productFamily == 'Education' ? ' and (ProductCode like \'SC%\' or ProductCode like \'CC%\' or ProductCode like \'MO%\')' : '';                  

        products = Database.query(queryStr);
        /* End GregB: 01/04/2016 */                    
                            
 /*       List<Product2> courses = [select id, name, IsActive, Points__c, Description, Product_Type__c, 
                                    Start_Date__c, End_date__c, Location__c, Total_Number_of_Seats__c, ProductCode,
                                    LMS_Code__c, Venue__c, Id_Prod__c,
                                    (select pricebook2.name, UnitPrice 
                                        from PriceBookEntries
                                        where pricebook2.name = 'Education Non Members'
                                        or pricebook2.name = 'Education Member') 
                                    from product2 where id in (
                                        select Product2id 
                                        from pricebookentry
                                        where (pricebook2.name = 'Education Non Members'
                                            or pricebook2.name = 'Education Member')
                                        and IsActive = true)
                                    and Family = 'Education' 
                                    and IsActive = true 
                                    and (ProductCode like 'SC%' or ProductCode like 'CC%' or ProductCode like 'MO%')]; */
        res.statusCode= 200;
        res.responseBody = Blob.valueOf(JSON.serialize(products));
    }
}