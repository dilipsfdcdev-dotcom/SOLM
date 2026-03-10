/**
 * Invocable wrapper: Get Case Summary
 * Delegates to ITHelpdeskAgentService.getCaseSummary
 */
public without sharing class ITHelpdesk_GetCaseSummary {

    public class Input {
        @InvocableVariable(label='User Id' required=true)
        public String userId;
    }

    public class Output {
        @InvocableVariable(label='Total Cases')
        public Integer totalCases;

        @InvocableVariable(label='New Count')
        public Integer newCount;

        @InvocableVariable(label='Open Count')
        public Integer openCount;

        @InvocableVariable(label='In Progress Count')
        public Integer inProgressCount;

        @InvocableVariable(label='Escalated Count')
        public Integer escalatedCount;

        @InvocableVariable(label='Waiting Count')
        public Integer waitingCount;

        @InvocableVariable(label='Closed Count')
        public Integer closedCount;

        @InvocableVariable(label='Critical High Count')
        public Integer criticalHighCount;

        @InvocableVariable(label='Medium Count')
        public Integer mediumCount;

        @InvocableVariable(label='Low Count')
        public Integer lowCount;

        @InvocableVariable(label='Recent Open Cases')
        public List<Case> recentOpenCases;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Case Summary'
                     description='Returns aggregated case counts by status and priority.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            ITHelpdeskAgentService.CaseSummaryData data =
                ITHelpdeskAgentService.getCaseSummary(inp.userId);

            Output out = new Output();
            out.totalCases       = data.totalCases;
            out.newCount         = data.newCount;
            out.openCount        = data.openCount;
            out.inProgressCount  = data.inProgressCount;
            out.escalatedCount   = data.escalatedCount;
            out.waitingCount     = data.waitingCount;
            out.closedCount      = data.closedCount;
            out.criticalHighCount = data.criticalHighCount;
            out.mediumCount      = data.mediumCount;
            out.lowCount         = data.lowCount;
            out.recentOpenCases  = data.recentOpenCases;
            out.message = 'Summary: ' + data.totalCases + ' total — '
                        + (data.newCount + data.openCount + data.inProgressCount
                           + data.escalatedCount + data.waitingCount)
                        + ' open, ' + data.closedCount + ' closed.';
            outputs.add(out);
        }
        return outputs;
    }
}
