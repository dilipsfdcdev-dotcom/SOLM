/**
 * Invocable wrapper: Update Case
 * Delegates to ITHelpdeskAgentService.updateCase
 */
public without sharing class ITHelpdesk_UpdateCase {

    public class Input {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Case Description')
        public String caseDescription;

        @InvocableVariable(label='Type')
        public String caseType;

        @InvocableVariable(label='Subject')
        public String subject;
    }

    public class Output {
        @InvocableVariable(label='Case Record')
        public Case caseRecord;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Update Case'
                     description='Updates one or more fields on an existing case.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                Case updated = ITHelpdeskAgentService.updateCase(
                    inp.caseId, inp.status, inp.priority,
                    inp.caseDescription, inp.caseType, inp.subject
                );
                if (updated != null) {
                    out.caseRecord = updated;
                    out.isSuccess = true;
                    out.message = 'Case ' + updated.CaseNumber + ' updated successfully.';
                } else {
                    out.isSuccess = false;
                    out.message = 'No fields provided to update.';
                }
            } catch (Exception e) {
                out.isSuccess = false;
                out.message = 'Failed to update case: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
