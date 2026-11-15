@isTest
private class MonthlySlaComplianceBatchTest {

    private static Id technicalRt() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Technical').getRecordTypeId();
    }

    @isTest
    static void batchProcessesLastMonthsCases() {
        Case ok     = new Case(Subject = 'OK', Status = 'New', Origin = 'Phone',
                               Urgency__c = 'Medium', RecordTypeId = technicalRt());
        Case breach = new Case(Subject = 'Breach', Status = 'New', Origin = 'Phone',
                               Urgency__c = 'Medium', RecordTypeId = technicalRt(),
                               SLA_Violated__c = true);
        insert new List<Case>{ ok, breach };
        Test.setCreatedDate(ok.Id, Datetime.now().addMonths(-1));
        Test.setCreatedDate(breach.Id, Datetime.now().addMonths(-1));
        MonthlySlaComplianceBatch.testRecipients = new List<String>{ 'manager@example.com' };

        Test.startTest();
        Id jobId = Database.executeBatch(new MonthlySlaComplianceBatch(), 200);
        Test.stopTest();

        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    }

    @isTest
    static void reportCalculatesPercentages() {
        String report = MonthlySlaComplianceBatch.buildReport(
            new Map<String, Integer>{ 'Billing' => 4 },
            new Map<String, Integer>{ 'Billing' => 1 });
        System.assert(report.contains('Billing: 4 cases, 1 breached, 75.0% within SLA'), report);
        System.assert(report.contains('OVERALL: 4 cases, 1 breached'), report);
    }

    @isTest
    static void reportHandlesNoCases() {
        String report = MonthlySlaComplianceBatch.buildReport(
            new Map<String, Integer>(), new Map<String, Integer>());
        System.assert(report.contains('No cases were created last month'), report);
    }

    @isTest
    static void schedulerStartsTheBatch() {
        MonthlySlaComplianceBatch.testRecipients = new List<String>{ 'manager@example.com' };
        Test.startTest();
        String jobId = System.schedule('Test Monthly SLA', '0 0 7 1 * ?', new MonthlySlaComplianceScheduler());
        Test.stopTest();
        System.assertNotEquals(null, [SELECT NextFireTime FROM CronTrigger WHERE Id = :jobId].NextFireTime);
    }
}