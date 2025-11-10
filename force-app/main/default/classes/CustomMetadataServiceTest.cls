@isTest
public class CustomMetadataServiceTest {
    private static final String ACC_NAME = 'AccountTest';
    private static final String CONTACT_NAME = 'ContactTest';
    private static final String PRODUCT2_NAME = 'ProductTest';

    private static CustomMetadataService metadataService = CustomMetadataService.getInstance();

    private static void setMetadata() {

        metadataService.setMetadataMock('Account', (List < Account > ) JSON.deserialize('[{"Name":"' + ACC_NAME + '"}]', List < Account > .class));

        metadataService.setMetadataMock('Contact', new List < Contact > {
            new Contact(LastName = CONTACT_NAME)
        });

        metadataService.setMetadataMock(new List < Product2 > {
            new Product2(Name = PRODUCT2_NAME)
        });
    }

    @isTest
    static void testMetadataService() {

        System.assertEquals(0, [SELECT Id FROM Account].size(), 'Expected no Accounts');
        System.assertEquals(0, metadataService.get([SELECT Id FROM Account]).size(), 'Expected no Accounts');

        setMetadata();

        List < Account > accounts = metadataService.get([SELECT Name FROM Account]);
        List < Contact > contacts = metadataService.get([SELECT LastName FROM Contact]);
        List < Product2 > products = metadataService.get('Product2', [SELECT Name FROM Product2]);
        
        System.assertEquals(accounts.size(), 1);
        System.assertEquals(accounts[0].Name, ACC_NAME);
    
        System.assertEquals(contacts.size(), 1);
        System.assertEquals(contacts[0].LastName, CONTACT_NAME);

        System.assertEquals(products.size(), 1);
        System.assertEquals(products[0].Name, PRODUCT2_NAME);
    }
}