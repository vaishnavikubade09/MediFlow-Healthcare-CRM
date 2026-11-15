@isTest
private class WeeklyCaseSummaryTest {

    private static Id technicalRt() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Technical').getRecordTypeId();
    }

    @isTest
    static void summaryContainsTheNumbers() {
        insert new Case(Subject = 'Test', Status = 'New', Origin = 'Phone',
                        Urgency__c = 'Medium', RecordTypeId = technicalRt());
        Test.startTest();
        String body = WeeklyCaseSummary.buildSummaryBody();
        Test.stopTest();
        System.assert(body.contains('Cases created: 1'), body);
        System.assert(body.contains('SLA compliance'), body);
    }

    @isTest
    static void emailIsSentWhenThereAreRecipients() {
        WeeklyCaseSummary.testRecipients = new List<String>{ 'supervisor@example.com' };
        Test.startTest();
        Integer sent = WeeklyCaseSummary.sendSummary();
        Test.stopTest();
        System.assertEquals(1, sent);
    }

    @isTest
    static void noEmailWithoutRecipients() {
        WeeklyCaseSummary.testRecipients = new List<String>();
        Test.startTest();
        Integer sent = WeeklyCaseSummary.sendSummary();
        Test.stopTest();
        System.assertEquals(0, sent);
    }

    @isTest
    static void canBeScheduled() {
        WeeklyCaseSummary.testRecipients = new List<String>{ 'supervisor@example.com' };
        Test.startTest();
        String jobId = System.schedule('Test Weekly Summary', '0 0 8 ? * MON', new WeeklyCaseSummary());
        Test.stopTest();
        System.assertNotEquals(null, [SELECT NextFireTime FROM CronTrigger WHERE Id = :jobId].NextFireTime);
    }
}