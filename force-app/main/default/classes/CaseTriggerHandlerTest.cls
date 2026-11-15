@isTest
private class CaseTriggerHandlerTest {

    private static Id rtId(String developerName) {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get(developerName).getRecordTypeId();
    }

    private static Patient__c newPatient(String suffix) {
        return new Patient__c(
            Name             = 'Test Patient ' + suffix,
            Email__c         = 'test.patient.' + suffix + '@example.com',
            Phone__c         = '9999999999',
            DOB__c = Date.newInstance(1990, 1, 1)
        );
    }

    private static Case newCase(Id patientId, String recordType, String origin) {
        return new Case(Subject = 'Test case', Status = 'New', Origin = origin,
                        Urgency__c = 'Medium', Patient__c = patientId,
                        RecordTypeId = rtId(recordType));
    }

    private static Id patientId() {
        return [SELECT Id FROM Patient__c LIMIT 1].Id;
    }

    @TestSetup
    static void makeData() {
        insert newPatient('A');
    }

    @isTest
    static void firstCaseIsAllowed() {
        Test.startTest();
        insert newCase(patientId(), 'Billing', 'Phone');
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void differentCaseTypeIsAllowed() {
        Id pid = patientId();
        insert newCase(pid, 'Billing', 'Phone');
        Test.startTest();
        insert newCase(pid, 'Appointment', 'Phone');
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void newCaseAllowedAfterOldOneClosed() {
        Id pid = patientId();
        Case first = newCase(pid, 'Billing', 'Phone');
        insert first;
        first.Status = 'Closed';
        update first;
        Test.startTest();
        insert newCase(pid, 'Billing', 'Phone');
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void emailDuplicateIsBlocked() {
    Id pid = patientId();
    insert newCase(pid, 'Billing', 'Phone');           // existing open Billing case

    Test.startTest();
    Database.SaveResult sr = Database.insert(newCase(pid, 'Billing', 'Email-Billings'), false);
    Test.stopTest();

    System.assert(!sr.isSuccess(), 'Email duplicate should be blocked');
    System.assertEquals(CaseTriggerHandler.DUPLICATE_ERROR, sr.getErrors()[0].getMessage());
    System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Patient__c = :pid]);
  }
    @isTest
    static void firstEmailCaseIsAllowed() {
    Id pid = patientId();

    Test.startTest();
    Database.SaveResult sr = Database.insert(newCase(pid, 'Billing', 'Email-Billings'), false);
    Test.stopTest();

    System.assert(sr.isSuccess(), 'First email case should be allowed: ' + sr.getErrors());
  }
    
    
    @isTest
    static void casesWithoutPatientAreNotChecked() {
        Test.startTest();
        insert new List<Case>{ newCase(null, 'Technical', 'Phone'), newCase(null, 'Technical', 'Phone') };
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void entitlementIsAssigned() {
    Account acc = new Account(Name = 'Test Hospital Patients', Rating = 'Hot', Phone = '9827387538');
    insert acc;
    Entitlement ent = new Entitlement(
        Name      = CaseTriggerHandler.ENTITLEMENT_NAME,
        AccountId = acc.Id,
        StartDate = Date.today().addDays(-1)
    );
    insert ent;

    Test.startTest();
    Case c = newCase(patientId(), 'Billing', 'Phone');
    c.AccountId = acc.Id;
    insert c;
    Test.stopTest();

    System.assertEquals(ent.Id, [SELECT EntitlementId FROM Case WHERE Id = :c.Id].EntitlementId);
}

    @isTest
    static void duplicateOpenCaseIsBlocked() {
        Id pid = patientId();
        insert newCase(pid, 'Billing', 'Phone');
        Test.startTest();
        Database.SaveResult sr = Database.insert(newCase(pid, 'Billing', 'Phone'), false);
        Test.stopTest();
        System.assert(!sr.isSuccess(), 'Duplicate should be blocked');
        System.assertEquals(CaseTriggerHandler.DUPLICATE_ERROR, sr.getErrors()[0].getMessage());
    }

    @isTest
    static void duplicateInSameInsertIsBlocked() {
        Id pid = patientId();
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(
            new List<Case>{ newCase(pid, 'Billing', 'Phone'), newCase(pid, 'Billing', 'Phone') }, false);
        Test.stopTest();
        System.assert(results[0].isSuccess());
        System.assert(!results[1].isSuccess());
    }

    @isTest
    static void bulkInsertWorks() {
        List<Patient__c> patients = new List<Patient__c>();
        for (Integer i = 0; i < 100; i++) {
            patients.add(newPatient('bulk' + i));
        }
        insert patients;
        List<Case> cases = new List<Case>();
        for (Patient__c p : patients) {
            cases.add(newCase(p.Id, 'Billing', 'Phone'));
            cases.add(newCase(p.Id, 'Appointment', 'Phone'));
        }
        Test.startTest();
        insert cases;
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE Patient__c IN :patients]);
    }
}