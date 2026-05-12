public without sharing class UserService {
    private static String userRegion;

    public static String getUserRegion() {
        if (userRegion == null) {
            userRegion = [SELECT Region__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]?.Region__c;
        }

        return userRegion;
    }

    @TestVisible
    private static void resetUserRegion() {
        userRegion = null;
    }
}