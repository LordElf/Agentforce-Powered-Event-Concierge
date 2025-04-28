public with sharing class FS_JoinSession {
    @InvocableMethod(label='Join Session'
        label='joinSession'
        description='Join a session'
    )
    public static List<FS_JoinSessionResponse> joinSession(List<FS_JoinSessionRequest> requests) {
        List<FS_JoinSessionResponse> responses = new List<FS_JoinSessionResponse>();
        List<String> contactIds = new List<String>();
        List<Id> sessionIds = new List<Id>();
        for (FS_JoinSessionRequest request : requests) {
            if (request.contactId != null) {
                contactIds.add(request.contactId);
            }
            if (request.sessionId != null) {
                sessionIds.add(request.sessionId);
            }
        }
        // get all the sessions from the sessions
        if (sessionIds.isEmpty()) {
            return responses;
        }
        Map<Id, Event_Session__c> sessionMap = new Map<Id, Event_Session__c>(
            [SELECT Id, Name, Description__c, Start_Time__c, End_Time__c, Event__c FROM Event_Session__c WHERE Id IN :sessionIds]
        );
        

        // get Session_Agenda__c records for the contact and session
        List<Session_Agenda__c> sessionAgendas = [SELECT Id, Session__c, Contact__c FROM Session_Agenda__c WHERE Contact__c IN :contactIds];
        MAP<Id, Set<Id>> contactIdsToSessionIds = new MAP<Id, Set<Id>>();
        for (Session_Agenda__c sessionAgenda : sessionAgendas) {
            if (!contactIdsToSessionIds.containsKey(sessionAgenda.Contact__c)) {
                contactIdsToSessionIds.put(sessionAgenda.Contact__c, new Set<Id>());
            }
            contactIdsToSessionIds.get(sessionAgenda.Contact__c).add(sessionAgenda.Session__c);
        }
        List<Session_Agenda__c> sessionAgendasToInsert = new List<Session_Agenda__c>();
        for (FS_JoinSessionRequest request : requests) {
            FS_JoinSessionResponse response = new FS_JoinSessionResponse();
            if (request.contactId != null && request.sessionId != null) {
                if (contactIdsToSessionIds.containsKey(request.contactId)) {
                    Set<Id> sessionIdsSet = contactIdsToSessionIds.get(request.contactId);
                    if (!sessionIdsSet.contains(request.sessionId)) {
                        Session_Agenda__c sessionAgenda = new Session_Agenda__c();
                        sessionAgenda.Name = sessionMap.get(request.sessionId).Name;
                        sessionAgenda.Contact__c = request.contactId;
                        sessionAgenda.Session__c = request.sessionId;
                        sessionAgenda.Event__c = sessionMap.get(request.sessionId).Event__c;
                        sessionAgenda.Enrollment_Status__c = 'Enrolled';
                        sessionAgendasToInsert.add(sessionAgenda);
                        response.success = true;
                    } else {
                        response.success = false;
                        response.errorMessage = 'Contact is already in the session';
                    }
                } else {
                    Session_Agenda__c sessionAgenda = new Session_Agenda__c();
                    sessionAgenda.Name = sessionMap.get(request.sessionId).Name;
                    sessionAgenda.Contact__c = request.contactId;
                    sessionAgenda.Session__c = request.sessionId;
                    sessionAgenda.Event__c = sessionMap.get(request.sessionId).Event__c;
                    sessionAgenda.Enrollment_Status__c = 'Enrolled';
                    sessionAgendasToInsert.add(sessionAgenda);
                    response.success = true;
                }
                responses.add(response);
            }
        }

        insert sessionAgendasToInsert;

        return responses;
    }

    // We need contactId and SessionId to join a session
    public class FS_JoinSessionRequest {
        @InvocableVariable(
            label='Contact Id'
            description='The contact id to join the session'
        )
        public String contactId;

        @InvocableVariable(
            label='Session Id'
            description='The session id to join the session'
        )
        public String sessionId;
    }

    public class FS_JoinSessionResponse {
        @InvocableVariable(
            label='Success'
            description='Whether the join session was successful'
        )
        public Boolean success;

        @InvocableVariable(
            label='Error Message'
            description='The error message if the join session was not successful'
        )
        public String errorMessage;
    }
}