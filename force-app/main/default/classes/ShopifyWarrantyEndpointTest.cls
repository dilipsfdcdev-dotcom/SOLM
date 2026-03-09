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
            AND    IsPersonType = TRUE
            AND    IsActive     = TRUE
            LIMIT  1
        ];
        return rt.Id;
    }

    /* ------------------------------------------------------------------ *
     * Utility: get or create InsuJet Lead RecordType Id
     * ------------------------------------------------------------------ */
    private static Id getInsujetLeadRtId() {
        List<RecordType> rts = [
            SELECT Id
            FROM   RecordType
            WHERE  SObjectType = 'Lead'
            AND    Name        = 'InsuJet'
            AND    IsActive    = TRUE
            LIMIT  1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    /* ------------------------------------------------------------------ *
     * Utility: set up RestContext for POST
     * ------------------------------------------------------------------ */
    private static RestResponse setupRestContext(String body) {
        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod  = 'POST';
        req.requestUri  = '/services/apexrest/shopify/warranty';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(body);
        RestContext.request  = req;
        RestContext.response = res;
        return res;
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 1️⃣  Blank request body → 400                                            *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testBlankBodyReturns400() {
        RestResponse res = setupRestContext('');

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(400, res.statusCode, 'Blank body should return 400');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 2️⃣  Existing Person Account with AccountSource = 'Insujet' is matched  *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testExistingInsujetPersonAccount() {
        Id paRt = getPersonAccountRt();

        Account existingPA = new Account(
            RecordTypeId      = paRt,
            FirstName         = 'Jane',
            LastName          = 'Doe',
            PersonEmail       = 'jane@example.com',
            PersonMobilePhone = '555-1111',
            AccountSource     = 'Insujet'
        );
        insert existingPA;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Jane Doe',
            'email'         => 'jane@example.com',
            'phone'         => '555-1111',
            'purchasedDate' => '2025-05-12',
            'serialNumber'  => 'SN-EXIST-001',
            'source'        => 'insujet-shopify',
            'country'       => 'France'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        Warranty__c w = [
            SELECT Account__c
            FROM   Warranty__c
            WHERE  Serial_Number__c = 'SN-EXIST-001'
            LIMIT  1
        ];
        System.assertEquals(existingPA.Id, w.Account__c,
            'Warranty should link to existing Insujet Person Account');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 3️⃣  Non-Insujet Account is NOT matched (forces new account creation)    *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testNonInsujetAccountNotMatched() {
        Id paRt = getPersonAccountRt();

        Account nonInsujetPA = new Account(
            RecordTypeId      = paRt,
            FirstName         = 'Alex',
            LastName          = 'Other',
            PersonEmail       = 'alex@example.com',
            PersonMobilePhone = '555-9999',
            AccountSource     = 'Web'
        );
        insert nonInsujetPA;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Alex Other',
            'email'         => 'alex@example.com',
            'phone'         => '555-9999',
            'purchasedDate' => '2025-06-01',
            'serialNumber'  => 'SN-NONINSU-001',
            'source'        => 'insujet',
            'country'       => 'France'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        // A new Insujet account should have been created
        List<Account> insujetAccts = [
            SELECT Id
            FROM   Account
            WHERE  PersonEmail   = 'alex@example.com'
            AND    AccountSource = 'Insujet'
        ];
        System.assertEquals(1, insujetAccts.size(),
            'A new Insujet Person Account should be created');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 4️⃣  Two warranties, same email → only one new Person Account created    *
 *     Second record uses invalid date to hit try/catch block               *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testCreatesNewPersonAccountOnce() {
        String newEmail = 'newbuyer@example.com';

        List<Object> payload = new List<Object>{
            new Map<String,Object>{
                'fullName'      => 'Sam Traveler',
                'email'         => newEmail,
                'phone'         => '555-2222',
                'purchasedDate' => '2025-05-13',
                'serialNumber'  => 'SN-NEW-001',
                'source'        => 'insujet'
            },
            new Map<String,Object>{
                'fullName'      => 'Sam Traveler',
                'email'         => newEmail,
                'phone'         => '555-2222',
                'purchasedDate' => 'not-a-date',
                'serialNumber'  => 'SN-NEW-002',
                'source'        => 'insujet'
            }
        };

        RestResponse res = setupRestContext(JSON.serialize(payload));

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        List<Account> acctList = [
            SELECT Id
            FROM   Account
            WHERE  PersonEmail   = :newEmail
            AND    AccountSource = 'Insujet'
        ];
        System.assertEquals(1, acctList.size(), 'Only one Person Account for same email');

        List<Warranty__c> wList = [
            SELECT Account__c
            FROM   Warranty__c
            WHERE  Serial_Number__c IN ('SN-NEW-001','SN-NEW-002')
        ];
        System.assertEquals(2, wList.size(), 'Two warranty records created');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 5️⃣  Lead conversion path with InsuJet RecordType                        *
 *     – Lead exists, Form_Submission__c and Case attached                  *
 *     – Endpoint converts Lead → PA, re-parents form + case, deletes Lead *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testLeadConversionWithFormAndCaseReparenting() {
        Id insujetRtId = getInsujetLeadRtId();
        if (insujetRtId == null) {
            // If InsuJet RT doesn't exist in org, skip gracefully
            return;
        }

        String em = 'convertme@example.com';

        Lead l = new Lead(
            RecordTypeId = insujetRtId,
            LastName     = 'Smith',
            Company      = 'Acme Inc.',
            Email        = em,
            Phone        = '555-3333'
        );
        insert l;

        // Child form submission attached to Lead
        Form_Submission__c fs = new Form_Submission__c(
            Lead__c = l.Id
        );
        insert fs;

        // Child case attached to Lead
        Case c = new Case(
            Lead__c = l.Id,
            Subject = 'Test Case for Lead Conversion'
        );
        insert c;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Bob Smith',
            'email'         => em,
            'phone'         => '555-3333',
            'purchasedDate' => '2025-05-15',
            'serialNumber'  => 'SN-LEAD-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        // Warranty created
        List<Warranty__c> wList = [
            SELECT Account__c
            FROM   Warranty__c
            WHERE  Serial_Number__c = 'SN-LEAD-001'
        ];
        System.assertEquals(1, wList.size());
        System.assertNotEquals(null, wList[0].Account__c, 'Warranty should be linked to account');

        // Form submission re-parented
        Form_Submission__c updatedFs = [
            SELECT Account__c
            FROM   Form_Submission__c
            WHERE  Id = :fs.Id
        ];
        System.assertNotEquals(null, updatedFs.Account__c,
            'Form submission should be re-parented to the converted account');

        // Case re-parented and Lead__c cleared
        Case updatedCase = [
            SELECT AccountId, Lead__c
            FROM   Case
            WHERE  Id = :c.Id
        ];
        System.assertNotEquals(null, updatedCase.AccountId,
            'Case should be re-parented to the converted account');
        System.assertEquals(null, updatedCase.Lead__c,
            'Case Lead__c should be cleared after conversion');

        // Original lead should be deleted
        List<Lead> remainingLeads = [
            SELECT Id FROM Lead WHERE Id = :l.Id
        ];
        System.assertEquals(0, remainingLeads.size(), 'Converted lead should be deleted');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 6️⃣  Non-InsuJet Lead is NOT picked up for conversion                    *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testNonInsujetLeadNotConverted() {
        String em = 'wrongrt@example.com';

        // Lead without InsuJet RecordType
        Lead l = new Lead(
            LastName = 'NoConvert',
            Company  = 'Other Corp',
            Email    = em,
            Phone    = '555-7777'
        );
        insert l;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'No Convert',
            'email'         => em,
            'phone'         => '555-7777',
            'purchasedDate' => '2025-06-01',
            'serialNumber'  => 'SN-NORT-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        // Lead should still exist (not converted)
        List<Lead> remainingLeads = [
            SELECT Id FROM Lead WHERE Id = :l.Id AND IsConverted = FALSE
        ];
        System.assertEquals(1, remainingLeads.size(),
            'Non-InsuJet lead should NOT be converted');

        // A new Person Account should be created instead
        List<Account> newAccts = [
            SELECT Id
            FROM   Account
            WHERE  PersonEmail   = :em
            AND    AccountSource = 'Insujet'
        ];
        System.assertEquals(1, newAccts.size(),
            'New Insujet account created since lead was skipped');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 7️⃣  Account name update – full name with space (FirstName + LastName)    *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testAccountNameUpdateWithSpace() {
        Id paRt = getPersonAccountRt();

        Account pa = new Account(
            RecordTypeId      = paRt,
            FirstName         = 'Old',
            LastName          = 'Name',
            PersonEmail       = 'namechange@example.com',
            AccountSource     = 'Insujet'
        );
        insert pa;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'New UpdatedName',
            'email'         => 'namechange@example.com',
            'phone'         => '555-4444',
            'purchasedDate' => '2025-07-01',
            'serialNumber'  => 'SN-NAME-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        Account updated = [
            SELECT FirstName, LastName
            FROM   Account
            WHERE  Id = :pa.Id
        ];
        System.assertEquals('New', updated.FirstName);
        System.assertEquals('UpdatedName', updated.LastName);
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 8️⃣  Account name update – single name (no space, LastName only)          *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testAccountNameUpdateSingleName() {
        Id paRt = getPersonAccountRt();

        Account pa = new Account(
            RecordTypeId      = paRt,
            FirstName         = 'ShouldClear',
            LastName          = 'OldLast',
            PersonEmail       = 'singlename@example.com',
            AccountSource     = 'Insujet'
        );
        insert pa;

        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Madonna',
            'email'         => 'singlename@example.com',
            'phone'         => '555-5555',
            'purchasedDate' => '2025-07-02',
            'serialNumber'  => 'SN-SINGLE-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        Account updated = [
            SELECT FirstName, LastName
            FROM   Account
            WHERE  Id = :pa.Id
        ];
        System.assertEquals(null, updated.FirstName,
            'FirstName should be cleared for single-name');
        System.assertEquals('Madonna', updated.LastName);
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 9️⃣  New Person Account with blank fullName → defaults to 'Unknown'      *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testBlankFullNameDefaultsToUnknown() {
        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => '',
            'email'         => 'noname@example.com',
            'phone'         => '555-6666',
            'purchasedDate' => '2025-08-01',
            'serialNumber'  => 'SN-BLANK-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        Account created = [
            SELECT LastName
            FROM   Account
            WHERE  PersonEmail   = 'noname@example.com'
            AND    AccountSource = 'Insujet'
            LIMIT  1
        ];
        System.assertEquals('Unknown', created.LastName,
            'Blank fullName should default LastName to Unknown');
    }

/*───────────────────────────────────────────────────────────────────────────*
 * 🔟  New Person Account with single-word fullName (no space)              *
 *───────────────────────────────────────────────────────────────────────────*/
    @IsTest
    static void testSingleWordFullNameNewAccount() {
        String body = JSON.serialize(new Map<String,Object>{
            'fullName'      => 'Cher',
            'email'         => 'cher@example.com',
            'phone'         => '555-8888',
            'purchasedDate' => '2025-08-05',
            'serialNumber'  => 'SN-SINGLE-NEW-001',
            'source'        => 'insujet'
        });

        RestResponse res = setupRestContext(body);

        Test.startTest();
            ShopifyWarrantyEndpoint.createWarranty();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);

        Account created = [
            SELECT FirstName, LastName
            FROM   Account
            WHERE  PersonEmail   = 'cher@example.com'
            AND    AccountSource = 'Insujet'
            LIMIT  1
        ];
        System.assertEquals('Cher', created.LastName);
    }
}