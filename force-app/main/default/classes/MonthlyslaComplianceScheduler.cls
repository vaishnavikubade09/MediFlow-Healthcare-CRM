public class MonthlyslaComplianceScheduler implements Schedulable { 
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MonthlyslaComplianceBatch(), 200);
    }
    

}