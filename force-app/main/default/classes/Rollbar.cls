/**
 * Installation:
 * 1. Create a new SF org.
 * 1. Create a new Rollbar project.
 * 41 Add `RollbarSettings__c` custom settings in Setup -> Custom Settings with custom field `AccessToken__c`
        and configure your Rollbar project access token.
 * 1. Add https://api.rollbar.com in `Remote Site Settings` in Salesforce Setup.
 * 2. Add email service in `Email Services` in Salesforce Setup pointint to RollbarExceptionEmailHandler class.
        Check `Active` box.
 * 3. Add Salesforce-generated email address from the added email service to `Apex Exception Email` addresses.
        Leave `Accept Email From` field empty.
 */
global with sharing class Rollbar {

    public static Rollbar instance() {
        if (Rollbar.instance == null) {
            Rollbar.instance = new Rollbar();
        }

        return Rollbar.instance;
    }

    public static Rollbar init()
    {
        RollbarSettings__c settings = RollbarSettings__c.getOrgDefaults();

        return Rollbar.init(
            settings.AccessToken__c,
            settings.Environment__c
        );
    }

    public static Rollbar init(String accessToken, String environment) {
        return Rollbar.init(new Config(accessToken, environment));
    }

    public static Rollbar init(Config config) {
        Rollbar instance = instance();
        instance.config = config;
        instance.notifier = new Notifier(instance.config);
        instance.initialized = true;
        return instance;
    }

    global static HttpResponse log(String level, String message) {
        return log(level, message, null, null);
    }

    global static HttpResponse log(String level, String message, Map<String, Object> custom) {
        return log(level, message, custom, null);
    }

    global static HttpResponse log(String level, String message, SendMethod method) {
        return log(level, message, null, method);
    }

    global static HttpResponse log(String level, String message, Map<String, Object> custom, SendMethod method) {
        Item item = new Item(message);
        item.custom = custom;

        return log(level, item, method);
    }

    // Keep this unpublished (public, not global) until Item interface can be frozen,
    // which might be never.
    public static HttpResponse log(String level, Item item, SendMethod method) {
        Rollbar instance = initializedInstance();

        return instance.notifier.log(level, item, method);
    }

    global static HttpResponse log(Exception exc) {
        return log(exc, null, null);
    }

    global static HttpResponse log(Exception exc, SendMethod method) {
        return log(exc, null, method);
    }

    global static HttpResponse log(Exception exc, Map<String, Object> custom) {
        return log(exc, custom, null);
    }

    global static HttpResponse log(Exception exc, Map<String, Object> custom, SendMethod method) {
        Item item = new Item(exc);
        item.custom = custom;

        return log('error', item, method);
    }

    global static HttpResponse log(ExceptionData exData) {
        Item item = new Item(exData);

        return log('error', item, SendMethod.SYNC);
    }

    public static Rollbar initializedInstance()
    {
        Rollbar instance = Rollbar.instance();
        if (!instance.initialized) {
            Rollbar.init();
        }

        return instance;
    }

    private Rollbar() {
    }

    public Notifier notifier() {
        return notifier;
    }

    public Config config() {
        return config;
    }

    private static Rollbar instance = null;
    private Config config = null;
    private Notifier notifier = null;
    private Boolean initialized = false;
}
