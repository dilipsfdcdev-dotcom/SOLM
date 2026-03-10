/**
 * Invocable wrapper: Get Case History
 * Delegates to ITHelpdeskAgentService.getCaseHistory
 */
public without sharing class ITHelpdesk_GetCaseHistory {

    public class Input {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;
    }

    public class Output {
        @InvocableVariable(label='History Summary')
        public String historySummary;

        @InvocableVariable(label='Comment Count')
        public Integer commentCount;

        @InvocableVariable(label='History Count')
        public Integer historyCount;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Case History'
                     description='Retrieves comments and field-change history for a case.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                ITHelpdeskAgentService.CaseHistoryData data =
                    ITHelpdeskAgentService.getCaseHistory(inp.caseId);
                out.historySummary = data.historySummary;
                out.commentCount  = data.comments.size();
                out.historyCount  = data.historyCount;
                out.isSuccess     = true;
                out.message       = 'Retrieved ' + data.comments.size() + ' comment(s) and '
                                  + data.historyCount + ' history record(s).';
            } catch (Exception e) {
                out.isSuccess = false;
                out.message   = 'Failed to retrieve case history: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
