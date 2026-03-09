/**
 * Invocable wrapper: Get Cases By Contact Id
 * Delegates to ITHelpdeskAgentService.getCasesByContactId
 */
public with sharing class ITHelpdesk_GetCasesByContact {

    public class Input {
        @InvocableVariable(label='Contact Id' required=true)
        public String contactId;
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

    @InvocableMethod(label='IT Helpdesk - Get Cases By Contact'
                     description='Returns all cases linked to a contact with counts.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            out.caseList = ITHelpdeskAgentService.getCasesByContactId(inp.contactId);
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
