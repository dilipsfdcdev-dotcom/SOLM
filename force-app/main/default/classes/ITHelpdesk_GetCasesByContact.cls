/**
 * Invocable wrapper: Get Cases By Owner Id
 * Delegates to ITHelpdeskAgentService.getCasesByOwnerId
 */
public without sharing class ITHelpdesk_GetCasesByContact {

    public class Input {
        @InvocableVariable(label='User Id' required=true)
        public String userId;
    }

    public class Output {
        @InvocableVariable(label='Case List')
        public List<Case> caseList;

        @InvocableVariable(label='Total Count')
        public Integer totalCount;

        @InvocableVariable(label='Open Count')
        public Integer openCount;

        @InvocableVariable(label='Closed Count')
        public Integer closedCount;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Cases By Owner'
                     description='Returns all cases owned by a user with counts.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            out.caseList = ITHelpdeskAgentService.getCasesByOwnerId(inp.userId);
            out.totalCount = out.caseList.size();
            Integer open = 0;
            Integer closed = 0;
            for (Case c : out.caseList) {
                if (c.Status == 'Closed') { closed++; } else { open++; }
            }
            out.openCount = open;
            out.closedCount = closed;
            out.message = 'Found ' + out.totalCount + ' case(s): ' + open + ' open, ' + closed + ' closed.';
            outputs.add(out);
        }
        return outputs;
    }
}
