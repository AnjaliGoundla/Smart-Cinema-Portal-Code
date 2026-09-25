global class SmartCinemaMaintenanceScheduler
    implements Schedulable {

    global void execute(SchedulableContext sc) {

        Database.executeBatch(
            new CinemaPermitExpiryBatch(),
            200
        );

        Database.executeBatch(
            new CinemaInspectionArchiveBatch(),
            200
        );
    }
}