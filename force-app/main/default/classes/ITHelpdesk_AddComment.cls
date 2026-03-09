/**
 * Invocable wrapper: Add Case Comment
 * Delegates to ITHelpdeskAgentService.addCaseComment
 */
public with sharing class ITHelpdesk_AddComment {

    public class Input {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;

        @InvocableVariable(label='Comment Body' required=true)
        public String commentBody;

        @InvocableVariable(label='Is Public')
        public Boolean isPublic;
    }

    public class Output {
        @InvocableVariable(label='Comment Id')
        public String commentId;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='IT Helpdesk - Add Case Comment'
                     description='Adds a comment to an existing case.'
                     category='IT Helpdesk')
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input inp : inputs) {
            Output out = new Output();
            try {
                CaseComment cc = ITHelpdeskAgentService.addCaseComment(
                    inp.caseId, inp.commentBody, inp.isPublic
                );
                out.commentId = cc.Id;
                out.isSuccess = true;
                out.message   = 'Comment added successfully.';
            } catch (Exception e) {
                out.isSuccess = false;
                out.message   = 'Failed to add comment: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}
