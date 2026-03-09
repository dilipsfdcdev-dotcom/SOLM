/**
 * ITHelpdeskAgentService
 * ──────────────────────────────────────────────────────────────────
 * Central business-logic class for the IT Helpdesk Agentforce Service Agent.
 * ALL case-management logic lives here. Individual @InvocableMethod wrapper
 * classes (ITHelpdesk_*) delegate to this service.
 *
 * To add a new action:
 *   1. Add the method here
 *   2. Create a thin invocable wrapper class (see ITHelpdesk_GetCase as example)
 *
 * Methods:
 *   getCaseByCaseNumber   – Retrieve a single case by CaseNumber + ContactId
 *   getCasesByContactId   – List all cases for a contact
 *   searchCases           – Search/filter by keyword, status, priority, date range
 *   getOverdueCases       – Cases open longer than N days
 *   createCase            – Create a new case, assign to Support queue
 *   updateCase            – Update fields on an existing case
 *   addCaseComment        – Add a CaseComment to a case
 *   closeCase             – Close with resolution details
 *   findSimilarCases      – Find similar/related cases across all contacts
 *   getCaseSummary        – Aggregated counts by status and priority
 *   getUrgentCases        – Critical/High priority open cases
 *   reassignCase          – Reassign a case to a different owner or queue
 *   getCaseHistory        – Retrieve comments and field-change history
 */
public with sharing class ITHelpdeskAgentService {

    // ─── Constants ───────────────────────────────────────────────
    public static final String SUPPORT_QUEUE_NAME = 'Support';
    public static final Set<String> OPEN_STATUSES = new Set<String>{
        'New', 'Open', 'In Progress', 'Escalated', 'Waiting on Customer'
    };

    // ─── Standard Case field list ────────────────────────────────
    private static final String CASE_FIELDS =
        'Id, CaseNumber, Subject, Status, Priority, Type, Origin, '
      + 'Description, CreatedDate, LastModifiedDate, ClosedDate, '
      + 'Owner.Name, Contact.Name, ContactId, AccountId';

    private static final String CASE_FIELDS_SHORT =
        'Id, CaseNumber, Subject, Status, Priority, Type, Origin, '
      + 'CreatedDate, LastModifiedDate, Owner.Name';


    // ═══════════════════════════════════════════════════════════════
    //  1. GET CASE BY CASE NUMBER
    // ═══════════════════════════════════════════════════════════════

    public static Case getCaseByCaseNumber(String contactId, String caseNumber) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, Origin,
                   Description, CreatedDate, LastModifiedDate, ClosedDate,
                   Owner.Name, Contact.Name, ContactId, AccountId
            FROM Case
            WHERE CaseNumber = :caseNumber
              AND ContactId  = :contactId
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }


    // ═══════════════════════════════════════════════════════════════
    //  2. GET CASES BY CONTACT ID
    // ═══════════════════════════════════════════════════════════════

    public static List<Case> getCasesByContactId(String contactId) {
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, Origin,
                   CreatedDate, LastModifiedDate, Owner.Name
            FROM Case
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    //  3. SEARCH CASES
    // ═══════════════════════════════════════════════════════════════

    public static List<Case> searchCases(String contactId, String keyword,
                                         String statusFilter, String priorityFilter,
                                         String dateFrom, String dateTo) {
        String query = 'SELECT Id, CaseNumber, Subject, Status, Priority, Type, '
                     + 'CreatedDate, LastModifiedDate, Owner.Name '
                     + 'FROM Case WHERE ContactId = :contactId';

        if (String.isNotBlank(statusFilter)) {
            query += ' AND Status = :statusFilter';
        }
        if (String.isNotBlank(priorityFilter)) {
            query += ' AND Priority = :priorityFilter';
        }
        if (String.isNotBlank(keyword)) {
            String likeKeyword = '%' + String.escapeSingleQuotes(keyword) + '%';
            query += ' AND (Subject LIKE \'' + likeKeyword + '\' OR Description LIKE \'' + likeKeyword + '\')';
        }
        if (String.isNotBlank(dateFrom)) {
            query += ' AND CreatedDate >= ' + String.escapeSingleQuotes(dateFrom) + 'T00:00:00Z';
        }
        if (String.isNotBlank(dateTo)) {
            query += ' AND CreatedDate <= ' + String.escapeSingleQuotes(dateTo) + 'T23:59:59Z';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 100';

        return Database.query(query);
    }


    // ═══════════════════════════════════════════════════════════════
    //  4. GET OVERDUE CASES
    // ═══════════════════════════════════════════════════════════════

    public static List<Case> getOverdueCases(String contactId, Integer daysOpen) {
        Integer days = (daysOpen != null && daysOpen > 0) ? daysOpen : 7;
        DateTime cutoff = DateTime.now().addDays(-days);
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type,
                   CreatedDate, LastModifiedDate, Owner.Name
            FROM Case
            WHERE ContactId  = :contactId
              AND Status IN :OPEN_STATUSES
              AND CreatedDate < :cutoff
            ORDER BY CreatedDate ASC
            LIMIT 100
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    //  5. CREATE CASE
    // ═══════════════════════════════════════════════════════════════

    public static Case createCase(String contactId, String subject, String description,
                                  String priority, String caseType, String origin) {
        Id supportQueueId = getSupportQueueId();

        Case newCase = new Case();
        newCase.ContactId   = contactId;
        newCase.Subject     = subject;
        newCase.Description = description;
        newCase.Priority    = String.isNotBlank(priority) ? priority : 'Medium';
        newCase.Type        = String.isNotBlank(caseType) ? caseType : null;
        newCase.Origin      = String.isNotBlank(origin)   ? origin   : 'Messaging';
        newCase.Status      = 'New';

        if (supportQueueId != null) {
            newCase.OwnerId = supportQueueId;
        }

        insert newCase;

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, Origin,
                   CreatedDate, Owner.Name, ContactId
            FROM Case
            WHERE Id = :newCase.Id
            LIMIT 1
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    //  6. UPDATE CASE
    // ═══════════════════════════════════════════════════════════════

    public static Case updateCase(String caseId, String status, String priority,
                                  String description, String caseType, String subject) {
        Case c = new Case(Id = caseId);
        Boolean hasChanges = false;

        if (String.isNotBlank(status))      { c.Status = status;           hasChanges = true; }
        if (String.isNotBlank(priority))    { c.Priority = priority;       hasChanges = true; }
        if (String.isNotBlank(description)) { c.Description = description; hasChanges = true; }
        if (String.isNotBlank(caseType))    { c.Type = caseType;           hasChanges = true; }
        if (String.isNotBlank(subject))     { c.Subject = subject;        hasChanges = true; }

        if (!hasChanges) {
            return null;
        }

        update c;

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type,
                   Description, CreatedDate, LastModifiedDate, Owner.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    //  7. ADD CASE COMMENT
    // ═══════════════════════════════════════════════════════════════

    public static CaseComment addCaseComment(String caseId, String commentBody, Boolean isPublic) {
        CaseComment cc = new CaseComment();
        cc.ParentId    = caseId;
        cc.CommentBody = commentBody;
        cc.IsPublished = (isPublic != null) ? isPublic : true;
        insert cc;
        return cc;
    }


    // ═══════════════════════════════════════════════════════════════
    //  8. CLOSE CASE
    // ═══════════════════════════════════════════════════════════════

    public static Case closeCase(String caseId, String resolutionSummary,
                                 String rootCause, String closureNotes) {
        Case existing = [
            SELECT Id, CaseNumber, Status, Description
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (existing.Status == 'Closed') {
            return null; // Already closed — caller should check
        }

        String fullResolution = 'Resolution: ' + resolutionSummary;
        if (String.isNotBlank(rootCause)) {
            fullResolution += '\nRoot Cause: ' + rootCause;
        }
        if (String.isNotBlank(closureNotes)) {
            fullResolution += '\nClosure Notes: ' + closureNotes;
        }

        existing.Status = 'Closed';
        existing.Description = (existing.Description != null ? existing.Description + '\n\n' : '')
                             + '--- Closure Details ---\n' + fullResolution;
        update existing;

        // Add closure comment
        CaseComment cc = new CaseComment();
        cc.ParentId    = existing.Id;
        cc.CommentBody = fullResolution;
        cc.IsPublished = true;
        insert cc;

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type,
                   ClosedDate, Owner.Name, Description
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    //  9. FIND SIMILAR CASES
    // ═══════════════════════════════════════════════════════════════

    public static List<Case> findSimilarCases(String keyword, String caseType) {
        String query = 'SELECT Id, CaseNumber, Subject, Status, Priority, Type, '
                     + 'Description, CreatedDate, Owner.Name '
                     + 'FROM Case WHERE Id != null';

        if (String.isNotBlank(caseType)) {
            query += ' AND Type = :caseType';
        }
        if (String.isNotBlank(keyword)) {
            String likeKeyword = '%' + String.escapeSingleQuotes(keyword) + '%';
            query += ' AND (Subject LIKE \'' + likeKeyword + '\' OR Description LIKE \'' + likeKeyword + '\')';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 50';

        return Database.query(query);
    }


    // ═══════════════════════════════════════════════════════════════
    // 10. GET CASE SUMMARY
    // ═══════════════════════════════════════════════════════════════

    public class CaseSummaryData {
        public Integer totalCases     = 0;
        public Integer newCount       = 0;
        public Integer openCount      = 0;
        public Integer inProgressCount = 0;
        public Integer escalatedCount  = 0;
        public Integer waitingCount    = 0;
        public Integer closedCount     = 0;
        public Integer criticalHighCount = 0;
        public Integer mediumCount     = 0;
        public Integer lowCount        = 0;
        public List<Case> recentOpenCases = new List<Case>();
    }

    public static CaseSummaryData getCaseSummary(String contactId) {
        List<Case> allCases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, CreatedDate
            FROM Case
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
        ];

        CaseSummaryData data = new CaseSummaryData();
        data.totalCases = allCases.size();

        for (Case c : allCases) {
            if (c.Status == 'New')                        data.newCount++;
            else if (c.Status == 'Open')                  data.openCount++;
            else if (c.Status == 'In Progress')           data.inProgressCount++;
            else if (c.Status == 'Escalated')             data.escalatedCount++;
            else if (c.Status == 'Waiting on Customer')   data.waitingCount++;
            else if (c.Status == 'Closed')                data.closedCount++;

            if (c.Priority == 'Critical' || c.Priority == 'High') data.criticalHighCount++;
            else if (c.Priority == 'Medium')                       data.mediumCount++;
            else if (c.Priority == 'Low')                          data.lowCount++;

            if (c.Status != 'Closed' && data.recentOpenCases.size() < 5) {
                data.recentOpenCases.add(c);
            }
        }
        return data;
    }


    // ═══════════════════════════════════════════════════════════════
    // 11. GET URGENT CASES
    // ═══════════════════════════════════════════════════════════════

    public static List<Case> getUrgentCases(String contactId) {
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type,
                   CreatedDate, LastModifiedDate, Owner.Name
            FROM Case
            WHERE ContactId = :contactId
              AND Status IN :OPEN_STATUSES
              AND Priority IN ('Critical', 'High')
            ORDER BY Priority ASC, CreatedDate ASC
            LIMIT 50
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    // 12. REASSIGN CASE
    // ═══════════════════════════════════════════════════════════════

    public static Case reassignCase(String caseId, String newOwnerId, String queueName) {
        Id ownerId;
        if (String.isNotBlank(newOwnerId)) {
            ownerId = newOwnerId;
        } else if (String.isNotBlank(queueName)) {
            List<Group> queues = [
                SELECT Id, Name FROM Group
                WHERE Type = 'Queue' AND DeveloperName = :queueName
                LIMIT 1
            ];
            if (queues.isEmpty()) {
                return null; // Queue not found
            }
            ownerId = queues[0].Id;
        } else {
            return null; // No target specified
        }

        Case c = new Case(Id = caseId, OwnerId = ownerId);
        update c;

        return [
            SELECT Id, CaseNumber, Subject, Status, Owner.Name
            FROM Case WHERE Id = :caseId LIMIT 1
        ];
    }


    // ═══════════════════════════════════════════════════════════════
    // 13. GET CASE HISTORY
    // ═══════════════════════════════════════════════════════════════

    public class CaseHistoryData {
        public List<CaseComment> comments = new List<CaseComment>();
        public String historySummary = '';
        public Integer historyCount = 0;
    }

    public static CaseHistoryData getCaseHistory(String caseId) {
        CaseHistoryData data = new CaseHistoryData();

        data.comments = [
            SELECT Id, CommentBody, CreatedBy.Name, CreatedDate, IsPublished
            FROM CaseComment
            WHERE ParentId = :caseId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<CaseHistory> histories = [
            SELECT Field, OldValue, NewValue, CreatedBy.Name, CreatedDate
            FROM CaseHistory
            WHERE CaseId = :caseId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        data.historyCount = histories.size();
        String summary = '';
        for (CaseHistory h : histories) {
            summary += h.CreatedDate.format() + ' — '
                     + h.CreatedBy.Name + ' changed '
                     + h.Field + ' from "' + String.valueOf(h.OldValue)
                     + '" to "' + String.valueOf(h.NewValue) + '"\n';
        }
        data.historySummary = String.isNotBlank(summary) ? summary : 'No field history recorded.';
        return data;
    }


    // ═══════════════════════════════════════════════════════════════
    //  HELPER METHODS
    // ═══════════════════════════════════════════════════════════════

    public static Id getSupportQueueId() {
        List<Group> queues = [
            SELECT Id FROM Group
            WHERE Type = 'Queue' AND DeveloperName = :SUPPORT_QUEUE_NAME
            LIMIT 1
        ];
        return queues.isEmpty() ? null : queues[0].Id;
    }
}
