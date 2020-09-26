import { LightningElement, wire, track, api } from 'lwc';
import getOrphanedProjects from '@salesforce/apex/OrphanedProjectController.getOrphanedProjects';
//import getOrphanedVolOpps from '@salesforce/apex/OrphanedProjectController.getOrphanedVolOpps';
import { updateRecord, getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/OrphanedProject__c.Id';
import VL_FIELD from '@salesforce/schema/OrphanedProject__c.VolunteerLeader__c';
import Id from '@salesforce/user/Id';

const COLS_EDIT = [
    { label: 'Volunteer Opportunity', fieldName: 'OpportunityName'},
    { label: 'Location', fieldName: 'LocationName'},
    { label: 'Level', fieldName: 'Level'},
    { label: 'Start Date/Time', fieldName: 'StartDateTime'},
    { label: 'End Date/Time', fieldName: 'EndDateTime'},
    {type: "button", typeAttributes: {  
        label: 'Claim',  
        name: 'Claim',  
        title: 'Claim',  
        disabled: false,  
        value: 'claim',  
        iconPosition: 'left'  
    }}
];

const COLS_READ = [
    { label: 'Volunteer Opportunity', fieldName: 'OpportunityName'},
    { label: 'Location', fieldName: 'LocationName'},
    { label: 'Level', fieldName: 'Level'},
    { label: 'Start Date/Time', fieldName: 'StartDateTime'},
    { label: 'End Date/Time', fieldName: 'EndDateTime'},
    { label: 'Volunteer Leader', fieldName: 'VLName'}
];

const USER_FIELDS = [
    'User.Name',
    'User.Contact.Id',
    'User.Contact.Name'
];

export default class OrphanedProjectsLwc extends LightningElement {
    userId = Id;
    orphanedProjects;
    claimedProjects;
    @track error;
    @track columns_edit = COLS_EDIT;
    @track columns_read = COLS_READ;
    @api isLoaded = false;
    @api successful = false;

    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    user;

    connectedCallback(){
       this.handleRefresh();
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
            var orphans = data.filter(p => !p.VolunteerLeader__c);
            var claimed = data.filter(p => p.VolunteerLeader__c != null);

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
                    EndDateTime: p.EndDateTime__c,
                    VLName: p.VolunteerLeader__r.Name
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

    handleClaim(event) {
        this.isLoaded = !this.isLoaded;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = event.detail.row.Id;
        fields[VL_FIELD.fieldApiName] = this.user.data.fields.Contact.value.id; 
        const recordInput = { fields };

        console.log('RECORDINPUT', recordInput);

        updateRecord(recordInput)
        .then(() => {
            this.isLoaded = !this.isLoaded;
            this.successful = true;
            this.handleRefresh();
        }).catch(error => {
            this.isLoaded = !this.isLoaded;
            this.error = error.body.message;
        });
    }
}