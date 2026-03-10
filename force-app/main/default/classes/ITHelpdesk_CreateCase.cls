/**
 * Invocable wrapper: Create Case
 * Delegates to ITHelpdeskAgentService.createCase
 */
public without sharing class ITHelpdesk_CreateCase {

    public class Input {
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        @InvocableVariable(label='Subject' required=true)
        public String subject;

        @InvocableVariable(label='Case Description' required=true)
        public String caseDescription;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Type')
        public String caseType;

        @InvocableVariable(label='Origin')
        public String origin;
    }

    public class Output {
        @InvocableVariable(label='Case Record')
        public Case caseRecord;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Case Id')
        public String caseId;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Create Case'
                     description='Creates a new support case owned by the user.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                Case created = ITHelpdeskAgentService.createCase(
                    inp.userId, inp.subject, inp.caseDescription,
                    inp.priority, inp.caseType, inp.origin
                );
                out.caseRecord = created;
                out.caseNumber = created.CaseNumber;
                out.caseId     = created.Id;
                out.isSuccess  = true;
                out.message    = 'Case ' + created.CaseNumber + ' has been created successfully.';
            } catch (Exception e) {
                out.isSuccess = false;
                out.message   = 'Failed to create case: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
