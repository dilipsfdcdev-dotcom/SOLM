/**
 * Invocable wrapper: Get Contact By Email
 * Delegates to ITHelpdeskAgentService.getContactByEmail
 */
public with sharing class ITHelpdesk_GetContactByEmail {

    public class Input {
        @InvocableVariable(label='Email Address' required=true)
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

    @InvocableMethod(label='IT Helpdesk - Get Contact By Email'
                     description='Looks up a Contact record by email address and returns the ContactId.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            Contact c = ITHelpdeskAgentService.getContactByEmail(inp.email);
            if (c != null) {
                out.contactId = c.Id;
                out.contactName = c.Name;
                out.isFound = true;
                out.message = 'Contact found: ' + c.Name;
            } else {
                out.contactId = null;
                out.contactName = null;
                out.isFound = false;
                out.message = 'No contact found with email: ' + inp.email;
            }
            outputs.add(out);
        }
        return outputs;
    }
}
