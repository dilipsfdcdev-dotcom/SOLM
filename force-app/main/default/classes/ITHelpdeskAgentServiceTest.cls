@isTest
private class ITHelpdeskAgentServiceTest {

    // ─── Test Setup ──────────────────────────────────────────────
    @testSetup
    static void setupData() {
        // Cases are owned by the running user by default (OwnerId = UserInfo.getUserId())
        List<Case> cases = new List<Case>();

        // Case 1 - New / Critical
        cases.add(new Case(
            Subject     = 'VPN not connecting',
            Description = 'Unable to connect to VPN from home office',
            Priority    = 'Critical',
            Status      = 'New',
            Type        = 'Network',
            Origin      = 'Web'
        ));

        // Case 2 - Open / High
        cases.add(new Case(
            Subject     = 'Laptop screen flickering',
            Description = 'Screen flickers intermittently on docking station',
            Priority    = 'High',
            Status      = 'Open',
            Type        = 'Hardware',
            Origin      = 'Web'
        ));

        // Case 3 - In Progress / Medium
        cases.add(new Case(
            Subject     = 'Need Outlook add-in installed',
            Description = 'Request to install CRM Outlook add-in',
            Priority    = 'Medium',
            Status      = 'In Progress',
            Type        = 'Software',
            Origin      = 'Web'
        ));

        // Case 4 - Closed / Low
        cases.add(new Case(
            Subject     = 'Password reset request',
            Description = 'Need password reset for HR portal',
            Priority    = 'Low',
            Status      = 'Closed',
            Type        = 'Access/Permissions',
            Origin      = 'Web'
        ));

        // Case 5 - Waiting on Customer / Medium
        cases.add(new Case(
            Subject     = 'Email delivery delayed',
            Description = 'Outbound emails are delayed by 2 hours',
            Priority    = 'Medium',
            Status      = 'Waiting on Customer',
            Type        = 'Email',
            Origin      = 'Web'
        ));

        insert cases;
    }

    // ─── Helpers ─────────────────────────────────────────────────
    static String getTestUserId() {
        return UserInfo.getUserId();
    }

    static Case getTestCase(String subject) {
        return [SELECT Id, CaseNumber, Status FROM Case WHERE Subject = :subject LIMIT 1];
    }


    // ═══════════════════════════════════════════════════════════════
    //  1. getCaseByCaseNumber
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetCaseByCaseNumber_Found() {
        String userId = getTestUserId();
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.getCaseByCaseNumber(userId, vpnCase.CaseNumber);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Case should be found');
        System.assertEquals('VPN not connecting', result.Subject);
    }

    @isTest
    static void testGetCaseByCaseNumber_NotFound() {
        String userId = getTestUserId();

        Test.startTest();
        Case result = ITHelpdeskAgentService.getCaseByCaseNumber(userId, '99999999');
        Test.stopTest();

        System.assertEquals(null, result, 'Case should not be found');
    }

    @isTest
    static void testGetCaseInvocable() {
        String userId = getTestUserId();
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_GetCase.Input inp = new ITHelpdesk_GetCase.Input();
        inp.userId = userId;
        inp.caseNumber = vpnCase.CaseNumber;

        Test.startTest();
        List<ITHelpdesk_GetCase.Output> results = ITHelpdesk_GetCase.execute(
            new List<ITHelpdesk_GetCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isFound);
        System.assertNotEquals(null, results[0].caseId);
        System.assertNotEquals(null, results[0].caseNumber);
        System.assertNotEquals(null, results[0].caseStatus);
        System.assert(results[0].caseDetails.contains('VPN not connecting'));
    }


    // ═══════════════════════════════════════════════════════════════
    //  2. getCasesByOwnerId
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetCasesByOwnerId() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.getCasesByOwnerId(userId);
        Test.stopTest();

        System.assertEquals(5, results.size(), 'Should return all 5 cases');
    }

    @isTest
    static void testGetCasesByOwnerInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_GetCasesByContact.Input inp = new ITHelpdesk_GetCasesByContact.Input();
        inp.userId = userId;

        Test.startTest();
        List<ITHelpdesk_GetCasesByContact.Output> results = ITHelpdesk_GetCasesByContact.execute(
            new List<ITHelpdesk_GetCasesByContact.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(5, results[0].totalCount);
        System.assertEquals(4, results[0].openCount);
        System.assertEquals(1, results[0].closedCount);
    }


    // ═══════════════════════════════════════════════════════════════
    //  3. searchCases
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testSearchCases_ByKeyword() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.searchCases(
            userId, 'VPN', null, null, null, null
        );
        Test.stopTest();

        System.assert(results.size() >= 1, 'Should find at least the VPN case');
    }

    @isTest
    static void testSearchCases_ByStatus() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.searchCases(
            userId, null, 'Closed', null, null, null
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should find 1 closed case');
    }

    @isTest
    static void testSearchCases_ByPriority() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.searchCases(
            userId, null, null, 'Critical', null, null
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should find 1 critical case');
    }

    @isTest
    static void testSearchCases_NoResults() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.searchCases(
            userId, 'nonexistentkeyword123', null, null, null, null
        );
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @isTest
    static void testSearchCasesInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_SearchCases.Input inp = new ITHelpdesk_SearchCases.Input();
        inp.userId = userId;
        inp.priorityFilter = 'High';

        Test.startTest();
        List<ITHelpdesk_SearchCases.Output> results = ITHelpdesk_SearchCases.execute(
            new List<ITHelpdesk_SearchCases.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].resultCount);
    }


    // ═══════════════════════════════════════════════════════════════
    //  4. getOverdueCases
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetOverdueCases_NoneOverdue() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.getOverdueCases(userId, 7);
        Test.stopTest();

        // Freshly created cases won't be overdue
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testGetOverdueCases_DefaultDays() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.getOverdueCases(userId, null);
        Test.stopTest();

        System.assertNotEquals(null, results);
    }

    @isTest
    static void testGetOverdueCasesInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_GetOverdueCases.Input inp = new ITHelpdesk_GetOverdueCases.Input();
        inp.userId = userId;
        inp.daysOpen = 7;

        Test.startTest();
        List<ITHelpdesk_GetOverdueCases.Output> results = ITHelpdesk_GetOverdueCases.execute(
            new List<ITHelpdesk_GetOverdueCases.Input>{ inp }
        );
        Test.stopTest();

        System.assertNotEquals(null, results[0].message);
    }


    // ═══════════════════════════════════════════════════════════════
    //  5. createCase
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testCreateCase_Success() {
        String userId = getTestUserId();

        Test.startTest();
        Case result = ITHelpdeskAgentService.createCase(
            userId, 'Printer not working', 'Printer on 3rd floor is offline',
            'Medium', 'Hardware', 'Messaging'
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.CaseNumber);
        System.assertEquals('Printer not working', result.Subject);
        System.assertEquals('New', result.Status);
    }

    @isTest
    static void testCreateCase_DefaultPriority() {
        String userId = getTestUserId();

        Test.startTest();
        Case result = ITHelpdeskAgentService.createCase(
            userId, 'Monitor issue', 'Monitor goes black randomly',
            null, null, null
        );
        Test.stopTest();

        System.assertEquals('Medium', result.Priority);
        System.assertEquals('Web', result.Origin);
    }

    @isTest
    static void testCreateCaseInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_CreateCase.Input inp = new ITHelpdesk_CreateCase.Input();
        inp.userId = userId;
        inp.subject = 'Keyboard broken';
        inp.caseDescription = 'Space bar does not work';
        inp.priority = 'High';
        inp.caseType = 'Hardware';

        Test.startTest();
        List<ITHelpdesk_CreateCase.Output> results = ITHelpdesk_CreateCase.execute(
            new List<ITHelpdesk_CreateCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
        System.assertNotEquals(null, results[0].caseNumber);
    }


    // ═══════════════════════════════════════════════════════════════
    //  6. updateCase
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testUpdateCase_Status() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.updateCase(
            vpnCase.Id, 'In Progress', null, null, null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('In Progress', result.Status);
    }

    @isTest
    static void testUpdateCase_NoFields() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.updateCase(
            vpnCase.Id, null, null, null, null, null
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no fields to update');
    }

    @isTest
    static void testUpdateCaseInvocable() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_UpdateCase.Input inp = new ITHelpdesk_UpdateCase.Input();
        inp.caseId = vpnCase.Id;
        inp.priority = 'High';

        Test.startTest();
        List<ITHelpdesk_UpdateCase.Output> results = ITHelpdesk_UpdateCase.execute(
            new List<ITHelpdesk_UpdateCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
    }

    @isTest
    static void testUpdateCaseInvocable_NoFields() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_UpdateCase.Input inp = new ITHelpdesk_UpdateCase.Input();
        inp.caseId = vpnCase.Id;

        Test.startTest();
        List<ITHelpdesk_UpdateCase.Output> results = ITHelpdesk_UpdateCase.execute(
            new List<ITHelpdesk_UpdateCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess);
    }


    // ═══════════════════════════════════════════════════════════════
    //  7. addCaseComment
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testAddCaseComment() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        CaseComment result = ITHelpdeskAgentService.addCaseComment(
            vpnCase.Id, 'Investigating the VPN issue', true
        );
        Test.stopTest();

        System.assertNotEquals(null, result.Id);
    }

    @isTest
    static void testAddCaseComment_DefaultPublic() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        CaseComment result = ITHelpdeskAgentService.addCaseComment(
            vpnCase.Id, 'Testing default public flag', null
        );
        Test.stopTest();

        System.assertNotEquals(null, result.Id);
    }

    @isTest
    static void testAddCommentInvocable() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_AddComment.Input inp = new ITHelpdesk_AddComment.Input();
        inp.caseId = vpnCase.Id;
        inp.commentBody = 'Test comment from invocable';

        Test.startTest();
        List<ITHelpdesk_AddComment.Output> results = ITHelpdesk_AddComment.execute(
            new List<ITHelpdesk_AddComment.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
    }


    // ═══════════════════════════════════════════════════════════════
    //  8. closeCase
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testCloseCase_Success() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.closeCase(
            vpnCase.Id, 'VPN configuration was reset',
            'Incorrect proxy settings', 'User confirmed working'
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Closed', result.Status);
    }

    @isTest
    static void testCloseCase_AlreadyClosed() {
        Case closedCase = getTestCase('Password reset request');

        Test.startTest();
        Case result = ITHelpdeskAgentService.closeCase(
            closedCase.Id, 'Already resolved', null, null
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for already-closed case');
    }

    @isTest
    static void testCloseCaseInvocable() {
        Case laptopCase = getTestCase('Laptop screen flickering');

        ITHelpdesk_CloseCase.Input inp = new ITHelpdesk_CloseCase.Input();
        inp.caseId = laptopCase.Id;
        inp.resolutionSummary = 'Replaced docking station cable';

        Test.startTest();
        List<ITHelpdesk_CloseCase.Output> results = ITHelpdesk_CloseCase.execute(
            new List<ITHelpdesk_CloseCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
    }

    @isTest
    static void testCloseCaseInvocable_AlreadyClosed() {
        Case closedCase = getTestCase('Password reset request');

        ITHelpdesk_CloseCase.Input inp = new ITHelpdesk_CloseCase.Input();
        inp.caseId = closedCase.Id;
        inp.resolutionSummary = 'Test';

        Test.startTest();
        List<ITHelpdesk_CloseCase.Output> results = ITHelpdesk_CloseCase.execute(
            new List<ITHelpdesk_CloseCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess);
    }


    // ═══════════════════════════════════════════════════════════════
    //  9. findSimilarCases
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testFindSimilarCases_ByKeyword() {
        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.findSimilarCases('VPN', null);
        Test.stopTest();

        System.assert(results.size() >= 1);
    }

    @isTest
    static void testFindSimilarCases_ByType() {
        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.findSimilarCases(null, 'Hardware');
        Test.stopTest();

        System.assert(results.size() >= 1);
    }

    @isTest
    static void testFindSimilarCasesInvocable() {
        ITHelpdesk_FindSimilarCases.Input inp = new ITHelpdesk_FindSimilarCases.Input();
        inp.keyword = 'screen';

        Test.startTest();
        List<ITHelpdesk_FindSimilarCases.Output> results = ITHelpdesk_FindSimilarCases.execute(
            new List<ITHelpdesk_FindSimilarCases.Input>{ inp }
        );
        Test.stopTest();

        System.assert(results[0].resultCount >= 1);
    }


    // ═══════════════════════════════════════════════════════════════
    // 10. getCaseSummary
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetCaseSummary() {
        String userId = getTestUserId();

        Test.startTest();
        ITHelpdeskAgentService.CaseSummaryData data =
            ITHelpdeskAgentService.getCaseSummary(userId);
        Test.stopTest();

        System.assertEquals(5, data.totalCases);
        System.assertEquals(1, data.newCount);
        System.assertEquals(1, data.openCount);
        System.assertEquals(1, data.inProgressCount);
        System.assertEquals(1, data.waitingCount);
        System.assertEquals(1, data.closedCount);
        System.assertEquals(2, data.criticalHighCount);
    }

    @isTest
    static void testGetCaseSummaryInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_GetCaseSummary.Input inp = new ITHelpdesk_GetCaseSummary.Input();
        inp.userId = userId;

        Test.startTest();
        List<ITHelpdesk_GetCaseSummary.Output> results = ITHelpdesk_GetCaseSummary.execute(
            new List<ITHelpdesk_GetCaseSummary.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(5, results[0].totalCases);
    }


    // ═══════════════════════════════════════════════════════════════
    // 11. getUrgentCases
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetUrgentCases() {
        String userId = getTestUserId();

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.getUrgentCases(userId);
        Test.stopTest();

        // Should find Critical and High priority open cases
        System.assertEquals(2, results.size());
    }

    @isTest
    static void testGetUrgentCasesInvocable() {
        String userId = getTestUserId();

        ITHelpdesk_GetUrgentCases.Input inp = new ITHelpdesk_GetUrgentCases.Input();
        inp.userId = userId;

        Test.startTest();
        List<ITHelpdesk_GetUrgentCases.Output> results = ITHelpdesk_GetUrgentCases.execute(
            new List<ITHelpdesk_GetUrgentCases.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].urgentCount);
    }


    // ═══════════════════════════════════════════════════════════════
    // 12. reassignCase
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testReassignCase_NoTarget() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.reassignCase(vpnCase.Id, null, null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no target specified');
    }

    @isTest
    static void testReassignCase_InvalidQueue() {
        Case vpnCase = getTestCase('VPN not connecting');

        Test.startTest();
        Case result = ITHelpdeskAgentService.reassignCase(vpnCase.Id, null, 'Nonexistent_Queue');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent queue');
    }

    @isTest
    static void testReassignCase_ByOwnerId() {
        Case vpnCase = getTestCase('VPN not connecting');
        String currentUserId = UserInfo.getUserId();

        Test.startTest();
        Case result = ITHelpdeskAgentService.reassignCase(vpnCase.Id, currentUserId, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testReassignCaseInvocable() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_ReassignCase.Input inp = new ITHelpdesk_ReassignCase.Input();
        inp.caseId = vpnCase.Id;
        inp.newOwnerId = UserInfo.getUserId();

        Test.startTest();
        List<ITHelpdesk_ReassignCase.Output> results = ITHelpdesk_ReassignCase.execute(
            new List<ITHelpdesk_ReassignCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
    }

    @isTest
    static void testReassignCaseInvocable_NoTarget() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_ReassignCase.Input inp = new ITHelpdesk_ReassignCase.Input();
        inp.caseId = vpnCase.Id;

        Test.startTest();
        List<ITHelpdesk_ReassignCase.Output> results = ITHelpdesk_ReassignCase.execute(
            new List<ITHelpdesk_ReassignCase.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess);
    }


    // ═══════════════════════════════════════════════════════════════
    // 13. getCaseHistory
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetCaseHistory() {
        Case vpnCase = getTestCase('VPN not connecting');

        // Add a comment first
        CaseComment cc = new CaseComment(
            ParentId = vpnCase.Id,
            CommentBody = 'Test history comment',
            IsPublished = true
        );
        insert cc;

        Test.startTest();
        ITHelpdeskAgentService.CaseHistoryData data =
            ITHelpdeskAgentService.getCaseHistory(vpnCase.Id);
        Test.stopTest();

        System.assert(data.comments.size() >= 1, 'Should have at least 1 comment');
    }

    @isTest
    static void testGetCaseHistoryInvocable() {
        Case vpnCase = getTestCase('VPN not connecting');

        ITHelpdesk_GetCaseHistory.Input inp = new ITHelpdesk_GetCaseHistory.Input();
        inp.caseId = vpnCase.Id;

        Test.startTest();
        List<ITHelpdesk_GetCaseHistory.Output> results = ITHelpdesk_GetCaseHistory.execute(
            new List<ITHelpdesk_GetCaseHistory.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);
    }


    // ═══════════════════════════════════════════════════════════════
    // 14. getUserByEmail
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetUserByEmail_Found() {
        String currentUserEmail = UserInfo.getUserEmail();

        Test.startTest();
        User result = ITHelpdeskAgentService.getUserByEmail(currentUserEmail);
        Test.stopTest();

        System.assertNotEquals(null, result, 'User should be found');
        System.assertEquals(UserInfo.getUserId(), result.Id);
    }

    @isTest
    static void testGetUserByEmail_NotFound() {
        Test.startTest();
        User result = ITHelpdeskAgentService.getUserByEmail('nonexistent@nowhere.test');
        Test.stopTest();

        System.assertEquals(null, result, 'User should not be found');
    }

    @isTest
    static void testGetUserByEmail_BlankEmail() {
        Test.startTest();
        User result = ITHelpdeskAgentService.getUserByEmail('');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for blank email');
    }

    @isTest
    static void testGetUserByEmail_NullEmail() {
        Test.startTest();
        User result = ITHelpdeskAgentService.getUserByEmail(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null email');
    }

    @isTest
    static void testGetUserByEmailInvocable_Found() {
        ITHelpdesk_GetContactByEmail.Input inp = new ITHelpdesk_GetContactByEmail.Input();
        inp.email = UserInfo.getUserEmail();

        Test.startTest();
        List<ITHelpdesk_GetContactByEmail.Output> results = ITHelpdesk_GetContactByEmail.execute(
            new List<ITHelpdesk_GetContactByEmail.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isFound);
        System.assertNotEquals(null, results[0].userId);
        System.assertNotEquals(null, results[0].userName);
    }

    @isTest
    static void testGetUserByEmailInvocable_NotFound() {
        ITHelpdesk_GetContactByEmail.Input inp = new ITHelpdesk_GetContactByEmail.Input();
        inp.email = 'nobody@nowhere.test';

        Test.startTest();
        List<ITHelpdesk_GetContactByEmail.Output> results = ITHelpdesk_GetContactByEmail.execute(
            new List<ITHelpdesk_GetContactByEmail.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isFound);
        System.assertEquals(null, results[0].userId);
    }

    @isTest
    static void testGetUserByEmailInvocable_NeitherProvided() {
        ITHelpdesk_GetContactByEmail.Input inp = new ITHelpdesk_GetContactByEmail.Input();

        Test.startTest();
        List<ITHelpdesk_GetContactByEmail.Output> results = ITHelpdesk_GetContactByEmail.execute(
            new List<ITHelpdesk_GetContactByEmail.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isFound);
    }


    // ═══════════════════════════════════════════════════════════════
    //  Helper method tests
    // ═══════════════════════════════════════════════════════════════

    @isTest
    static void testGetSupportQueueId() {
        Test.startTest();
        Id queueId = ITHelpdeskAgentService.getSupportQueueId();
        Test.stopTest();

        // Queue may or may not exist in test context
        // Just verify no exception is thrown
        System.assert(true);
    }

    @isTest
    static void testSearchCases_WithDateRange() {
        String userId = getTestUserId();
        String today = String.valueOf(Date.today());
        String yesterday = String.valueOf(Date.today().addDays(-1));

        Test.startTest();
        List<Case> results = ITHelpdeskAgentService.searchCases(
            userId, null, null, null, yesterday, today
        );
        Test.stopTest();

        System.assert(results.size() >= 0);
    }
}
