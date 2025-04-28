public with sharing class FS_GetEventByTopic {
    @InvocableMethod(label='Get Event By Topic'
        label='getEventByTopic'
        description='Get the events by topic'
    )
    public static List<FS_GetEventByTopicResponse> getEventByTopic(List<FS_GetEventByTopicRequest> requests) {
        List<FS_GetEventByTopicResponse> responses = new List<FS_GetEventByTopicResponse>();
        Set<String> topics = new Set<String>();
        for (FS_GetEventByTopicRequest request : requests) {
            if (request.topics != null && !request.topics.isEmpty()) {
                topics.addAll(request.topics);
            }
        }
        if (topics.isEmpty()) {
            return responses;
        }
        // Query event sessions
        List<Event_Session__c> eventSessions = [SELECT Id, Name, Topic__c, Event__c, Event__r.Name, Start_Time__c, End_Time__c FROM Event_Session__c WHERE Topic__c IN :topics];
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
        for (FS_GetEventByTopicRequest request : requests) {
            FS_GetEventByTopicResponse response = new FS_GetEventByTopicResponse();
            response.events = events;
            response.eventSessions = eventSessions;
            responses.add(response);
        }
        return responses;
    }

    public class FS_GetEventByTopicRequest {
        @InvocableVariable(
            label='Topic'
            description='The topics to get events for, the options are: "Artificial Intelligence", "Data Analytics", "Robotics", "Cybersecurity", "Emerging Technologies", "Innovation in STEM Education", and "VIP Experience"'
        )
        public List<String> topics;
    }

    public class FS_GetEventByTopicResponse {
        @InvocableVariable(
            label='Events'
            description='The events that match the topics'
        )
        public List<Event__c> events;

        @InvocableVariable(
            label='Event Sessions'
            description='The event sessions that match the topics'
        )
        public List<Event_Session__c> eventSessions;
    }
}