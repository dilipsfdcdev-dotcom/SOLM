/**
 * Invocable wrapper: Get Urgent Cases
 * Delegates to ITHelpdeskAgentService.getUrgentCases
 */
public without sharing class ITHelpdesk_GetUrgentCases {

    public class Input {
        @InvocableVariable(label='User Id' required=true)
        public String userId;
    }

    public class Output {
        @InvocableVariable(label='Urgent Case List')
        public List<Case> urgentCaseList;

        @InvocableVariable(label='Urgent Count')
        public Integer urgentCount;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Urgent Cases'
                     description='Returns open Critical and High priority cases.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            out.urgentCaseList = ITHelpdeskAgentService.getUrgentCases(inp.userId);
            out.urgentCount = out.urgentCaseList.size();
            out.message = out.urgentCount > 0
                ? out.urgentCount + ' urgent case(s) require attention.'
                : 'No urgent cases at this time.';
            outputs.add(out);
        }
        return outputs;
    }
}
