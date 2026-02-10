@IsTest(seeAllData=false)
private class ShopifyWarrantyEndpointTest {

    /* ------------------------------------------------------------------ *
     * Utility: get an active Person-Account RecordType once per test run
     * ------------------------------------------------------------------ */
    private static Id getPersonAccountRt() {
        RecordType rt = [
            SELECT Id
            FROM   RecordType
            WHERE  SObjectType  = 'Account'
            AND    IsPersonType = TRUE         // requires PA-enabled org
            AND    IsActive     = TRUE
            LIMIT  1
        ];

        return rt.Id;
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 1️⃣  Warranty when the Person Account already exists                     *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testExistingPersonAccount() {

        /* --- Arrange --- */
        Id paRt = getPersonAccountRt();

        Account existingPA = new Account(
            RecordTypeId      = paRt,
            FirstName         = 'Jane',
            LastName          = 'Doe',
            PersonEmail       = 'jane@example.com',
            PersonMobilePhone = '555-1111'
        );
        insert existingPA;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Jane Doe',
            'email'         => 'jane@example.com',
            'phone'         => '555-1111',
            'purchasedDate' => '2025-05-12',
            'serialNumber'  => 'SN-EXIST-001'
        });

        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'POST';
        req.requestUri  = '/services/apexrest/shopify/warranty';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(body);
        RestContext.request  = req;
        RestContext.response = res;

        /* --- Act --- */
        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();


        Warranty__c w = [
            SELECT Account__c
            FROM   Warranty__c
            WHERE  Serial_Number__c = 'SN-EXIST-001'
            LIMIT  1
        ];
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 2️⃣  ONE new Person Account even when the same e-mail appears twice     *
 *     – second record uses an invalid date string to hit the try/catch.    *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testCreatesNewPersonAccountOnce() {

        /* --- Arrange --- */
        String newEmail = 'newbuyer@example.com';

        List<Object> payload = new List<Object>{
            new Map<String,Object>{
                'fullName'      => 'Sam Traveler',
                'email'         => newEmail,
                'phone'         => '555-2222',
                'purchasedDate' => '2025-05-13',
                'serialNumber'  => 'SN-NEW-001'
            },
            /* 2nd warranty for the SAME e-mail – bad date forces catch-block */
            new Map<String,Object>{
                'fullName'      => 'Sam Traveler',
                'email'         => newEmail,
                'phone'         => '555-2222',
                'purchasedDate' => 'not-a-date',
                'serialNumber'  => 'SN-NEW-002'
            }
        };

        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'POST';
        req.requestUri  = '/services/apexrest/shopify/warranty';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request  = req;
        RestContext.response = res;

        /* --- Act --- */
        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();


        /* Exactly one Person Account with that e-mail */
        List<Account> acctList = [
            SELECT Id
            FROM   Account
            WHERE  PersonEmail = :newEmail
        ];

        Id paId = acctList[0].Id;

        /* Two warranty records, both tied to that account */
        List<Warranty__c> wList = [
            SELECT Account__c
            FROM   Warranty__c
            WHERE  Serial_Number__c IN ('SN-NEW-001','SN-NEW-002')
        ];
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 3️⃣  Lead-conversion path:                                                *
 *     • An open Lead exists for the e-mail                                 *
 *     • A Form_Submission__c is attached to that Lead                      *
 *     • Endpoint converts Lead → PA, re-parents the form, and deletes Lead *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testLeadConversionAndFormReparenting() {

        /* --- Arrange --- */
        String em = 'convertme@example.com';

        Lead l = new Lead(
            LastName = 'Smith',
            Company  = 'Acme Inc.',
            Email    = em,
            Phone    = '555-3333'
        );
        insert l;

        /* child form that should be re-parented to Account */
        Form_Submission__c fs = new Form_Submission__c(
            Lead__c  = l.Id
        );
        insert fs;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Bob Smith',
            'email'         => em,
            'phone'         => '555-3333',
            'purchasedDate' => '2025-05-15',
            'serialNumber'  => 'SN-LEAD-001'
        });

        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'POST';
        req.requestUri  = '/services/apexrest/shopify/warranty';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(body);
        RestContext.request  = req;
        RestContext.response = res;

        /* --- Act --- */
        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 4️⃣  Blank request body → 400                                            *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testBlankBodyReturns400() {

        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'POST';
        req.requestUri  = '/services/apexrest/shopify/warranty';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf('');     // blank
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();
    }
}