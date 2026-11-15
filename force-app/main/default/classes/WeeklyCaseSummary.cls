public without sharing class WeeklyCaseSummary implements Schedulable {

    public static final String SUPERVISOR_ROLE = 'Supervisor';

    @TestVisible
    private static List<String> testRecipients;

    public void execute(SchedulableContext sc) {
        sendSummary();
    }

    public static Integer sendSummary() {
        List<String> recipients = getRecipients();
        if (recipients.isEmpty()) {
            return 0;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        mail.setSubject('Weekly Case Summary – week ending ' + Date.today().format());
        mail.setPlainTextBody(buildSummaryBody());
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        return 1;
    }

    public static String buildSummaryBody() {
        Datetime since = Datetime.now().addDays(-7);

        Integer created   = [SELECT COUNT() FROM Case WHERE CreatedDate >= :since];
        Integer closed    = [SELECT COUNT() FROM Case WHERE ClosedDate >= :since];
        Integer openNow   = [SELECT COUNT() FROM Case WHERE IsClosed = false];
        Integer breached  = [SELECT COUNT() FROM Case WHERE CreatedDate >= :since AND SLA_violated__c = true];
        Integer escalated = [SELECT COUNT() FROM Case WHERE CreatedDate >= :since AND IsEscalated = true];

        Decimal compliance = created == 0
            ? 100
            : ((Decimal)(created - breached) / created * 100).setScale(1);

        String byDept = '';
        for (AggregateResult ar : [
                SELECT Department__c dept, COUNT(Id) total FROM Case
                WHERE CreatedDate >= :since GROUP BY Department__c]) {
            Object dept = ar.get('dept');
            byDept += '  - ' + (dept == null ? 'Unassigned' : String.valueOf(dept))
                    + ': ' + ar.get('total') + '\n';
        }

        return 'Weekly Case Summary (last 7 days)\n\n'
             + 'Cases created: '   + created    + '\n'
             + 'Cases closed: '    + closed     + '\n'
             + 'Open right now: '  + openNow    + '\n'
             + 'SLA breaches: '    + breached   + '\n'
             + 'SLA compliance: '  + compliance + '%\n'
             + 'Escalated cases: ' + escalated  + '\n\n'
             + 'New cases by department:\n' + byDept;
    }

    private static List<String> getRecipients() {
        if (testRecipients != null) {
            return testRecipients;
        }
        List<String> emails = new List<String>();
        for (User u : [SELECT Email FROM User
                       WHERE IsActive = true AND UserRole.Name = :SUPERVISOR_ROLE]) {
            emails.add(u.Email);
        }
        return emails;
    }
}