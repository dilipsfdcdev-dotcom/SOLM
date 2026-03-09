/**
 * Invocable wrapper: Search Cases
 * Delegates to ITHelpdeskAgentService.searchCases
 */
public with sharing class ITHelpdesk_SearchCases {

    public class Input {
        @InvocableVariable(label='Contact Id' required=true)
        public String contactId;

        @InvocableVariable(label='Keyword')
        public String keyword;

        @InvocableVariable(label='Status Filter')
        public String statusFilter;

        @InvocableVariable(label='Priority Filter')
        public String priorityFilter;

        @InvocableVariable(label='Date From (YYYY-MM-DD)')
        public String dateFrom;

        @InvocableVariable(label='Date To (YYYY-MM-DD)')
        public String dateTo;
    }

    public class Output {
        @InvocableVariable(label='Case List')
        public List<Case> caseList;

        @InvocableVariable(label='Result Count')
        public Integer resultCount;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Search Cases'
                     description='Search cases by keyword, status, priority, or date range.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            out.caseList = ITHelpdeskAgentService.searchCases(
                inp.contactId, inp.keyword, inp.statusFilter,
                inp.priorityFilter, inp.dateFrom, inp.dateTo
            );
            out.resultCount = out.caseList.size();
            out.message = out.resultCount > 0
                ? 'Found ' + out.resultCount + ' matching case(s).'
                : 'No cases matched your search criteria.';
            outputs.add(out);
        }
        return outputs;
    }
}
