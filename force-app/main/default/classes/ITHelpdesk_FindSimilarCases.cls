/**
 * Invocable wrapper: Find Similar Cases
 * Delegates to ITHelpdeskAgentService.findSimilarCases
 */
public with sharing class ITHelpdesk_FindSimilarCases {

    public class Input {
        @InvocableVariable(label='Keyword')
        public String keyword;

        @InvocableVariable(label='Case Type')
        public String caseType;

        @InvocableVariable(label='Include Resolutions')
        public Boolean includeResolutions;
    }

    public class Output {
        @InvocableVariable(label='Similar Case List')
        public List<Case> similarCaseList;

        @InvocableVariable(label='Result Count')
        public Integer resultCount;

        @InvocableVariable(label='Has Pattern')
        public Boolean hasPattern;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Find Similar Cases'
                     description='Finds similar cases by keyword or type across all contacts.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            out.similarCaseList = ITHelpdeskAgentService.findSimilarCases(inp.keyword, inp.caseType);
            out.resultCount = out.similarCaseList.size();
            out.hasPattern = out.resultCount >= 3;
            out.message = out.resultCount > 0
                ? 'Found ' + out.resultCount + ' similar case(s).'
                  + (out.hasPattern ? ' A pattern has been detected — consider escalation.' : '')
                : 'No similar cases found.';
            outputs.add(out);
        }
        return outputs;
    }
}
