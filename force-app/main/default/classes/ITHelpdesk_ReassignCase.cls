/**
 * Invocable wrapper: Reassign Case
 * Delegates to ITHelpdeskAgentService.reassignCase
 */
public without sharing class ITHelpdesk_ReassignCase {

    public class Input {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;

        @InvocableVariable(label='New Owner Id' description='User Id or Queue Id to reassign to')
        public String newOwnerId;

        @InvocableVariable(label='Queue Name' description='Queue developer name if reassigning to a queue')
        public String queueName;
    }

    public class Output {
        @InvocableVariable(label='Case Record')
        public Case caseRecord;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Reassign Case'
                     description='Reassigns a case to a different user or queue.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                Case reassigned = ITHelpdeskAgentService.reassignCase(
                    inp.caseId, inp.newOwnerId, inp.queueName
                );
                if (reassigned != null) {
                    out.caseRecord = reassigned;
                    out.isSuccess = true;
                    out.message = 'Case ' + reassigned.CaseNumber + ' reassigned to ' + reassigned.Owner.Name + '.';
                } else {
                    out.isSuccess = false;
                    out.message = 'Could not reassign. Please provide a valid owner Id or queue name.';
                }
            } catch (Exception e) {
                out.isSuccess = false;
                out.message = 'Failed to reassign case: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
