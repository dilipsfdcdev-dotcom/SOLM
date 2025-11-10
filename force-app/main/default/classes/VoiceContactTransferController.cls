public with sharing class VoiceContactTransferController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchTerm) {
        if (String.isBlank(searchTerm)) return new List<Contact>();

        return [
            SELECT Id, Name, Phone
            FROM Contact
            WHERE Name LIKE :('%' + searchTerm + '%') AND Phone != null
            LIMIT 10
        ];
    }
}