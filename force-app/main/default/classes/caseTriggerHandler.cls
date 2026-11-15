public without sharing class caseTriggerHandler {

    public static final String ENTITLEMENT_NAME = 'Standard Patient Support';
    public static final String DUPLICATE_ERROR =
        'This patient already has an open case of this type. Please update the existing case instead.';

    public static void beforeInsert(List<Case> newCases) {
        assignEntitlement(newCases);
        preventDuplicateOpenCases(newCases);
    }

    @TestVisible
    private static void assignEntitlement(List<Case> newCases) {
        List<Entitlement> ents = [
            SELECT Id FROM Entitlement WHERE Name = :ENTITLEMENT_NAME LIMIT 1
        ];
        if (ents.isEmpty()) {
            return;
        }
        for (Case c : newCases) {
            if (c.EntitlementId == null) {
                c.EntitlementId = ents[0].Id;
            }
        }
    }

    @TestVisible
    private static void preventDuplicateOpenCases(List<Case> newCases) {
        Set<Id> patientIds = new Set<Id>();
        for (Case c : newCases) {
            if (isCheckable(c)) {
                patientIds.add(c.Patient__c);
            }
        }
        if (patientIds.isEmpty()) {
            return;
        }

        Set<String> existingKeys = new Set<String>();
        for (Case existing : [
                SELECT Patient__c, RecordTypeId FROM Case
                WHERE Patient__c IN :patientIds AND IsClosed = false]) {
            existingKeys.add(buildKey(existing.Patient__c, existing.RecordTypeId));
        }

        Set<String> keysInThisInsert = new Set<String>();
        for (Case c : newCases) {
            if (!isCheckable(c)) {
                continue;
            }
            String key = buildKey(c.Patient__c, c.RecordTypeId);
            if (existingKeys.contains(key) || keysInThisInsert.contains(key)) {
                c.addError(DUPLICATE_ERROR);
            } else {
                keysInThisInsert.add(key);
            }
        }
    }

    private static Boolean isCheckable(Case c) {
    return c.Patient__c != null;
}

    private static String buildKey(Id patientId, Id recordTypeId) {
        return String.valueOf(patientId) + '|' + String.valueOf(recordTypeId);
    }
}