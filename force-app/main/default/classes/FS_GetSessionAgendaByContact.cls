public with sharing class FS_GetSessionAgendaByContact {
    @InvocableMethod(
        label='Get Session Agenda By Contact'
        description='Get all session agenda items for a contact and return as HTML table'
    )
    public static List<FS_GetSessionAgendaByContactResponse> getSessionAgendaByContact(List<FS_GetSessionAgendaByContactRequest> requests) {
        List<FS_GetSessionAgendaByContactResponse> responses = new List<FS_GetSessionAgendaByContactResponse>();
        Set<String> contactIds = new Set<String>();
        
        // Collect all contact IDs from requests
        for (FS_GetSessionAgendaByContactRequest request : requests) {
            if (request.contactId != null) {
                contactIds.add(request.contactId);
            }
        }
        
        if (contactIds.isEmpty()) {
            return responses;
        }
        
        // Query Session_Agenda__c records with related session information
        List<Session_Agenda__c> sessionAgendas = [
            SELECT 
                Id, 
                Contact__c, 
                Session__c, 
                Session__r.Name,
                Session__r.Start_Time__c, 
                Session__r.End_Time__c,
                Session__r.Topic__c,
                Session__r.Location__c
            FROM Session_Agenda__c 
            WHERE Contact__c IN :contactIds
            ORDER BY Session__r.Start_Time__c ASC
        ];
        
        // Create a map to store session agendas by contact ID
        Map<String, List<Session_Agenda__c>> contactToAgendas = new Map<String, List<Session_Agenda__c>>();
        
        // Populate the map
        for (Session_Agenda__c agenda : sessionAgendas) {
            if (!contactToAgendas.containsKey(agenda.Contact__c)) {
                contactToAgendas.put(agenda.Contact__c, new List<Session_Agenda__c>());
            }
            contactToAgendas.get(agenda.Contact__c).add(agenda);
        }
        
        // Create responses for each request
        for (FS_GetSessionAgendaByContactRequest request : requests) {
            FS_GetSessionAgendaByContactResponse response = new FS_GetSessionAgendaByContactResponse();
            
            List<Session_Agenda__c> contactAgendas = contactToAgendas.get(request.contactId);
            if (contactAgendas != null && !contactAgendas.isEmpty()) {
                response.htmlTable = generateHtmlTable(contactAgendas);
                response.sessionAgendas = contactAgendas;
                response.success = true;
            } else {
                response.htmlTable = '<table><tr><td>No sessions found for this contact.</td></tr></table>';
                response.success = false;
                response.errorMessage = 'No session agendas found for the provided contact ID';
            }
            
            responses.add(response);
        }
        
        return responses;
    }
    
    private static String generateHtmlTable(List<Session_Agenda__c> agendas) {
        String htmlTable = '<table style="border-collapse: collapse; width: 100%; border: 1px solid #ddd;">';
        
        // Add table header
        htmlTable += '<thead>' +
                    '<tr style="background-color: #f2f2f2;">' +
                    '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Session</th>' +
                    '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Topic</th>' +
                    '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Start Time</th>' +
                    '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">End Time</th>' +
                    '<th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Location</th>' +
                    '</tr>' +
                    '</thead><tbody>';
        
        // Add table rows
        for (Session_Agenda__c agenda : agendas) {
            String sessionName = agenda.Session__r.Name != null ? agenda.Session__r.Name : 'N/A';
            String topic = agenda.Session__r.Topic__c != null ? agenda.Session__r.Topic__c : 'N/A';
            String startTime = agenda.Session__r.Start_Time__c != null ? 
                agenda.Session__r.Start_Time__c.format('MMM dd, yyyy h:mm a') : 'N/A';
            String endTime = agenda.Session__r.End_Time__c != null ? 
                agenda.Session__r.End_Time__c.format('MMM dd, yyyy h:mm a') : 'N/A';
            String location = agenda.Session__r.Location__c != null ? 
                agenda.Session__r.Location__c : 'N/A';
            
            htmlTable += '<tr>' +
                        '<td style="border: 1px solid #ddd; padding: 8px;">' + sessionName + '</td>' +
                        '<td style="border: 1px solid #ddd; padding: 8px;">' + topic + '</td>' +
                        '<td style="border: 1px solid #ddd; padding: 8px;">' + startTime + '</td>' +
                        '<td style="border: 1px solid #ddd; padding: 8px;">' + endTime + '</td>' +
                        '<td style="border: 1px solid #ddd; padding: 8px;">' + location + '</td>' +
                        '</tr>';
        }
        
        htmlTable += '</tbody></table>';
        return htmlTable;
    }
    
    public class FS_GetSessionAgendaByContactRequest {
        @InvocableVariable(
            label='Contact Id'
            description='The contact ID to get session agenda items for'
            required=true
        )
        public String contactId;
    }
    
    public class FS_GetSessionAgendaByContactResponse {
        @InvocableVariable(
            label='HTML Table'
            description='The HTML table representation of the session agenda'
        )
        public String htmlTable;
        
        @InvocableVariable(
            label='Session Agendas'
            description='The session agenda records for the contact'
        )
        public List<Session_Agenda__c> sessionAgendas;
        
        @InvocableVariable(
            label='Success'
            description='Whether the retrieval was successful'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Error Message'
            description='The error message if the retrieval was not successful'
        )
        public String errorMessage;
    }
}