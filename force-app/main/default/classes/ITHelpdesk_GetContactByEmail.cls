/**
 * Invocable wrapper: Resolve User Identity
 * Looks up a User record by email address.
 * Delegates to ITHelpdeskAgentService.getUserByEmail
 */
public with sharing class ITHelpdesk_GetContactByEmail {

    public class Input {
        @InvocableVariable(label='Email Address' required=false)
        public String email;
    }

    public class Output {
        @InvocableVariable(label='User Id')
        public String userId;

        @InvocableVariable(label='User Name')
        public String userName;

        @InvocableVariable(label='Is Found')
        public Boolean isFound;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Resolve User Identity'
                     description='Looks up a User record by email address and returns the UserId and name.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();

            if (String.isNotBlank(inp.email)) {
                User u = ITHelpdeskAgentService.getUserByEmail(inp.email);
                if (u != null) {
                    out.userId = u.Id;
                    out.userName = u.Name;
                    out.isFound = true;
                    out.message = 'User found: ' + u.Name;
                } else {
                    out.isFound = false;
                    out.message = 'No active user found with email: ' + inp.email;
                }
            } else {
                out.isFound = false;
                out.message = 'No email provided.';
            }

            outputs.add(out);
        }
        return outputs;
    }
}
