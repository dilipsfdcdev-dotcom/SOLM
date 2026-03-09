/**
 * Invocable wrapper: Get Case By Case Number
 * Delegates to ITHelpdeskAgentService.getCaseByCaseNumber
 */
public with sharing class ITHelpdesk_GetCase {

    public class Input {
        @InvocableVariable(label='Contact Id' required=true)
        public String contactId;

        @InvocableVariable(label='Case Number' required=true)
        public String caseNumber;
    }

    public class Output {
        @InvocableVariable(label='Case Record')
        public Case caseRecord;

        @InvocableVariable(label='Is Found')
        public Boolean isFound;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Get Case By Case Number'
                     description='Returns a case matching the given case number for the contact.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            Case c = ITHelpdeskAgentService.getCaseByCaseNumber(inp.contactId, inp.caseNumber);
            if (c != null) {
                out.caseRecord = c;
                out.isFound = true;
                out.message = 'Case ' + c.CaseNumber + ' found.';
            } else {
                out.isFound = false;
                out.message = 'No case found with number ' + inp.caseNumber + ' for your account.';
            }
            outputs.add(out);
        }
        return outputs;
    }
}
