/**
 * Invocable wrapper: Get Overdue Cases
 * Delegates to ITHelpdeskAgentService.getOverdueCases
 */
public with sharing class ITHelpdesk_GetOverdueCases {

    public class Input {
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        @InvocableVariable(label='Days Open')
        public Integer daysOpen;
    }

    public class Output {
        @InvocableVariable(label='Overdue Case List')
        public List<Case> overdueCaseList;

        @InvocableVariable(label='Overdue Count')
        public Integer overdueCount;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Overdue Cases'
                     description='Returns cases open longer than a specified number of days.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            Integer days = (inp.daysOpen != null && inp.daysOpen > 0) ? inp.daysOpen : 7;
            out.overdueCaseList = ITHelpdeskAgentService.getOverdueCases(inp.userId, days);
            out.overdueCount = out.overdueCaseList.size();
            out.message = out.overdueCount > 0
                ? out.overdueCount + ' case(s) have been open for more than ' + days + ' days.'
                : 'No overdue cases found.';
            outputs.add(out);
        }
        return outputs;
    }
}
