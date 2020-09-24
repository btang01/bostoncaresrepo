import { LightningElement, wire, track, api } from 'lwc';
import getOrphanedProjects from '@salesforce/apex/OrphanedProjectController.getOrphanedProjects';
//import getOrphanedVolOpps from '@salesforce/apex/OrphanedProjectController.getOrphanedVolOpps';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/OrphanedProject__c.Id';
import VLEMAIL_FIELD from '@salesforce/schema/OrphanedProject__c.VolunteerLeaderEmail__c';

const COLS_EDIT = [
    { label: 'Volunteer Opportunity', fieldName: 'OpportunityName'},
    { label: 'Location', fieldName: 'LocationName'},
    { label: 'Level', fieldName: 'Level'},
    { label: 'Start Date/Time', fieldName: 'StartDateTime'},
    { label: 'End Date/Time', fieldName: 'EndDateTime'},
    { label: 'Volunteer Leader Email', fieldName: 'VolunteerLeaderEmail__c', type: 'Email', editable: true}
];

const COLS_READ = [
    { label: 'Volunteer Opportunity', fieldName: 'OpportunityName'},
    { label: 'Location', fieldName: 'LocationName'},
    { label: 'Level', fieldName: 'Level'},
    { label: 'Start Date/Time', fieldName: 'StartDateTime'},
    { label: 'End Date/Time', fieldName: 'EndDateTime'},
    { label: 'Volunteer Leader Email', fieldName: 'VolunteerLeaderEmail__c', type: 'Email'}
];

export default class OrphanedProjectsLwc extends LightningElement {
    orphanedProjects;
    claimedProjects;
    @track error;
    @track columns_edit = COLS_EDIT;
    @track columns_read = COLS_READ;
    @track draftValues = [];
    @api isLoaded = false;
    @api successful = false;

    connectedCallback(){
       this.handleRefresh();
    }

    handleSave(event) {
        this.isLoaded = !this.isLoaded;

        const recordInputs = event.detail.draftValues.slice().map(draft => {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = draft.Id;
            fields[VLEMAIL_FIELD.fieldApiName] = draft.VolunteerLeaderEmail__c;
            return {fields};
        });

        console.log('RECORDINPUTS', recordInputs);

        /* Note: the updateRecord() function only works if the guest profile has VA/MA to the OrphanedProject__c object.
         * R/U/VA was not enough. I had to add D/MA in order for this to work.
         */
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises)
        .then(() => {
            this.isLoaded = !this.isLoaded;
            this.draftValues = [];
            this.successful = true;
            this.handleRefresh();
        }).catch(error => {
            this.isLoaded = !this.isLoaded;
            this.error = error.body.message;
        });
    }

    handleCloseSuccess(event) {
        this.successful = false;
    }

    handleCloseError(event) {
        this.error = '';
    }

    handleRefresh() {
        getOrphanedProjects()
        .then(data => {
            console.log(data);
            var orphans = data.filter(p => !p.VolunteerLeaderEmail__c);
            var claimed = data.filter(p => p.VolunteerLeaderEmail__c != null);

            this.orphanedProjects = orphans.map((p) => 
                Object.assign({}, p, {OpportunityName: p.VolunteerOpportunity__r.Name, 
                    LocationName: p.Location__r.Name,
                    Level: p.Level__c,
                    StartDateTime: p.StartDateTime__c,
                    EndDateTime: p.EndDateTime__c
                })
            );

            this.claimedProjects = claimed.map((p) => 
                Object.assign({}, p, {OpportunityName: p.VolunteerOpportunity__r.Name, 
                    LocationName: p.Location__r.Name,
                    Level: p.Level__c,
                    StartDateTime: p.StartDateTime__c,
                    EndDateTime: p.EndDateTime__c
                })
            );

            this.isLoaded = true;
        })
        .catch(error => {
            this.error = error;
            this.isLoaded = true;
            this.orphanedProjects = undefined;
            this.claimedProjects = undefined;
        });
    }
}