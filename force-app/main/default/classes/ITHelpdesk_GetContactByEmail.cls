/**
 * Invocable wrapper: Resolve Contact Identity
 * If contactId is already provided (from messaging session), verifies and passes it through.
 * Otherwise, looks up the Contact by email address.
 * Delegates to ITHelpdeskAgentService.getContactByEmail
 */
public with sharing class ITHelpdesk_GetContactByEmail {

    public class Input {
        @InvocableVariable(label='Contact Id' required=false)
        public String contactId;

        @InvocableVariable(label='Email Address' required=false)
        public String email;
    }

    public class Output {
        @InvocableVariable(label='Contact Id')
        public String contactId;

        @InvocableVariable(label='Contact Name')
        public String contactName;

        @InvocableVariable(label='Is Found')
        public Boolean isFound;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Resolve Contact Identity'
                     description='Resolves user identity: verifies existing ContactId or looks up Contact by email.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();

            // If contactId is already provided, verify and pass through
            if (String.isNotBlank(inp.contactId)) {
                List<Contact> contacts = [
                    SELECT Id, Name FROM Contact WHERE Id = :inp.contactId LIMIT 1
                ];
                if (!contacts.isEmpty()) {
                    out.contactId = contacts[0].Id;
                    out.contactName = contacts[0].Name;
                    out.isFound = true;
                    out.message = 'Contact verified: ' + contacts[0].Name;
                } else {
                    out.isFound = false;
                    out.message = 'No contact found with Id: ' + inp.contactId;
                }
            }
            // Otherwise, look up by email
            else if (String.isNotBlank(inp.email)) {
                Contact c = ITHelpdeskAgentService.getContactByEmail(inp.email);
                if (c != null) {
                    out.contactId = c.Id;
                    out.contactName = c.Name;
                    out.isFound = true;
                    out.message = 'Contact found: ' + c.Name;
                } else {
                    out.isFound = false;
                    out.message = 'No contact found with email: ' + inp.email;
                }
            }
            // Neither provided
            else {
                out.isFound = false;
                out.message = 'No contactId or email provided.';
            }

            outputs.add(out);
        }
        return outputs;
    }
}
