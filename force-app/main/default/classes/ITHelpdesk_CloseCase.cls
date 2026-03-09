/**
 * Invocable wrapper: Close Case
 * Delegates to ITHelpdeskAgentService.closeCase
 */
public with sharing class ITHelpdesk_CloseCase {

    public class Input {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;

        @InvocableVariable(label='Resolution Summary' required=true)
        public String resolutionSummary;

        @InvocableVariable(label='Root Cause')
        public String rootCause;

        @InvocableVariable(label='Closure Notes')
        public String closureNotes;
    }

    public class Output {
        @InvocableVariable(label='Case Record')
        public Case caseRecord;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Close Case'
                     description='Closes a case with a resolution summary and optional root cause.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                Case closed = ITHelpdeskAgentService.closeCase(
                    inp.caseId, inp.resolutionSummary,
                    inp.rootCause, inp.closureNotes
                );
                if (closed != null) {
                    out.caseRecord = closed;
                    out.isSuccess = true;
                    out.message = 'Case ' + closed.CaseNumber + ' has been closed successfully.';
                } else {
                    out.isSuccess = false;
                    out.message = 'Case is already closed.';
                }
            } catch (Exception e) {
                out.isSuccess = false;
                out.message = 'Failed to close case: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
