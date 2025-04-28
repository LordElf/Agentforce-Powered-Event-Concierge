public with sharing class FS_GetEventForUser {
    @InvocableMethod(label='Get Event For User'
        label='getEventForUser'
        description='Get the events for a user based on the message session id'
    )
    public static List<FS_GetEventForUserResponse> getEventForUser(List<FS_GetEventForUserRequest> requests) {
        List<FS_GetEventForUserResponse> responses = new List<FS_GetEventForUserResponse>();
        Set<String> contactIds = new Set<String>();
        for (FS_GetEventForUserRequest request : requests) {
            if (request.messageSessionEndUserContactId != null) {
                contactIds.add(request.messageSessionEndUserContactId);
            }
        }
        if (contactIds.isEmpty()) {
            return responses;
        }
        // Query contacts
        List<Contact> contacts = [SELECT Id, Name, Interests__c FROM Contact WHERE Id IN :contactIds];
        Set<String> interestedTopic = new Set<String>();
        for (Contact contact : contacts) {
            if (contact.Interests__c != null) {
                List<String> interests = contact.Interests__c.split(';');
                for (String interest : interests) {
                    if (String.isNotBlank(interest)) {
                        interestedTopic.add(interest);
                    }
                }
            }
        }
        System.debug('Interested topics: ' + interestedTopic);

        // Find all the event session the topics are in contact.Interests__c
        //SELECT Id, Name, Topic__c FROM Event_Session__c 
        List<Event_Session__c> eventSessions = 
            [SELECT Id, Name, Topic__c, Event__c, Event__r.Name, Start_Time__c, End_Time__c  FROM Event_Session__c WHERE Topic__c IN :interestedTopic];
        System.debug('Event sessions: ' + eventSessions);

        // extract the events from the event sessions
        Set<Id> eventIds = new Set<Id>();
        for (Event_Session__c eventSession : eventSessions) {
            if (eventSession.Event__c != null) {
                eventIds.add(eventSession.Event__c);
            }
        }
        System.debug('Event ids: ' + eventIds);
        // Query events
        List<Event__c> events = [SELECT Id, Name, Description__c FROM Event__c WHERE Id IN :eventIds];
        System.debug('Events: ' + events);
        // Create the response
        for (FS_GetEventForUserRequest request : requests) {
            FS_GetEventForUserResponse response = new FS_GetEventForUserResponse();
            response.eventNames = events;
            response.eventSessions = eventSessions;
            responses.add(response);
        }
        return responses;
    }

    public class FS_GetEventForUserRequest {
        @InvocableVariable(
            label='Customer_Contact_Id'
            description='MessagingSession.Customer_Contact_Id from the context variables.'
        )
        public String messageSessionEndUserContactId;
    }

    public class FS_GetEventForUserResponse {
        @InvocableVariable(
            label='Interested Events'
            description='The events the user is interested in'
        )
        public List<Event__c> eventNames;

        @InvocableVariable(
            label='Event Session'
            description='The event session the user is interested in'
        )
        public List<Event_Session__c> eventSessions;
    }
}