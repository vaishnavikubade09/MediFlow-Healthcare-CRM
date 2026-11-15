public without sharing class MonthlyslaComplianceBatch  
        implements Database.Batchable<SObject>, Database.Stateful {

    public static final String MANAGEMENT_ROLE = 'Admin';

    @TestVisible
    private static List<String> testRecipients;

    public Map<String, Integer> totalByType    = new Map<String, Integer>();
    public Map<String, Integer> breachedByType = new Map<String, Integer>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecordType.Name, SLA_Violated__c
            FROM Case WHERE CreatedDate = LAST_MONTH
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        for (Case c : scope) {
            String caseType = (c.RecordType != null) ? c.RecordType.Name : 'Unknown';
            addOne(totalByType, caseType);
            if (c.SLA_Violated__c == true) {
                addOne(breachedByType, caseType);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<String> recipients = getRecipients();
        if (recipients.isEmpty()) {
            return;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        mail.setSubject('Monthly SLA Compliance Report');
        mail.setPlainTextBody(buildReport(totalByType, breachedByType));
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    public static String buildReport(Map<String, Integer> totals, Map<String, Integer> breaches) {
        String body = 'Monthly SLA Compliance Report (last month)\n\n';
        if (totals.isEmpty()) {
            return body + 'No cases were created last month.';
        }
        Integer allTotal = 0;
        Integer allBreached = 0;
        for (String caseType : totals.keySet()) {
            Integer t = totals.get(caseType);
            Integer b = breaches.containsKey(caseType) ? breaches.get(caseType) : 0;
            allTotal += t;
            allBreached += b;
            body += caseType + ': ' + t + ' cases, ' + b + ' breached, '
                  + percent(t, b) + '% within SLA\n';
        }
        body += '\nOVERALL: ' + allTotal + ' cases, ' + allBreached + ' breached, '
              + percent(allTotal, allBreached) + '% within SLA';
        return body;
    }

    private static Decimal percent(Integer total, Integer breached) {
        if (total == 0) {
            return 100;
        }
        return ((Decimal)(total - breached) / total * 100).setScale(1);
    }

    private static void addOne(Map<String, Integer> counts, String key) {
        counts.put(key, (counts.containsKey(key) ? counts.get(key) : 0) + 1);
    }

    private static List<String> getRecipients() {
        if (testRecipients != null) {
            return testRecipients;
        }
        List<String> emails = new List<String>();
        for (User u : [SELECT Email FROM User
                       WHERE IsActive = true AND UserRole.Name = :MANAGEMENT_ROLE]) {
            emails.add(u.Email);
        }
        return emails;
    }
}