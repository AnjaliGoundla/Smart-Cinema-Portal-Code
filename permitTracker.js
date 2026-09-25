import { LightningElement, api, wire } from 'lwc';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import NAME_FIELD from '@salesforce/schema/Permit_Application__c.Name';
import STATUS_FIELD from '@salesforce/schema/Permit_Application__c.Status__c';
import PERMIT_TYPE_FIELD from '@salesforce/schema/Permit_Application__c.Permit_Type__c';
import APPLICATION_CATEGORY_FIELD from '@salesforce/schema/Permit_Application__c.Application_Category__c';
import CINEMA_NAME_FIELD from '@salesforce/schema/Permit_Application__c.Cinema_Name__c';
import APPLICANT_NAME_FIELD from '@salesforce/schema/Permit_Application__c.Applicant_Name__c';
import PERMIT_FEE_FIELD from '@salesforce/schema/Permit_Application__c.Permit_Fee__c';
import CREATED_DATE_FIELD from '@salesforce/schema/Permit_Application__c.CreatedDate';

const FIELDS = [
    NAME_FIELD,
    STATUS_FIELD,
    PERMIT_TYPE_FIELD,
    APPLICATION_CATEGORY_FIELD,
    CINEMA_NAME_FIELD,
    APPLICANT_NAME_FIELD,
    PERMIT_FEE_FIELD,
    CREATED_DATE_FIELD
];

export default class PermitTracker extends LightningElement {

    @api recordId;

    permitNumber = '';
    displayStatus = '';
    currentStatus = '';

    permitType = '';
    applicationCategory = '';
    cinemaName = '';
    applicantName = '';
    permitFee;
    createdDate;

    isRejected = false;
    showGrievanceForm = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredPermit({ error, data }) {

        if (data) {

            const status = getFieldValue(data, STATUS_FIELD);

            this.permitNumber =
                getFieldValue(data, NAME_FIELD);

            this.displayStatus = status;

            this.permitType =
                getFieldValue(data, PERMIT_TYPE_FIELD);

            this.applicationCategory =
                getFieldValue(data, APPLICATION_CATEGORY_FIELD);

            this.cinemaName =
                getFieldValue(data, CINEMA_NAME_FIELD);

            this.applicantName =
                getFieldValue(data, APPLICANT_NAME_FIELD);

            this.permitFee =
                getFieldValue(data, PERMIT_FEE_FIELD);

            this.createdDate =
                getFieldValue(data, CREATED_DATE_FIELD);

            this.isRejected =
                status === 'Rejected';

            if (status === 'Under Review') {
                this.currentStatus = 'Review';
            } else if (status === 'Submitted') {
                this.currentStatus = 'Submitted';
            } else if (status === 'Approved') {
                this.currentStatus = 'Approved';
            } else if (status === 'Issued') {
                this.currentStatus = 'Issued';
            } else {
                this.currentStatus = 'Submitted';
            }

        } else if (error) {

            this.showToast(
                'Error',
                'Failed to load permit application.',
                'error'
            );
        }
    }

    handleRaiseGrievance() {
        this.showGrievanceForm = true;
    }

    handleCancelGrievance() {
        this.showGrievanceForm = false;
    }

    handleGrievanceSuccess() {

        this.showGrievanceForm = false;

        this.showToast(
            'Success',
            'Your grievance has been submitted.',
            'success'
        );
    }

    handleUploadFinished(event) {

        const uploadedFiles =
            event.detail.files.length;

        this.showToast(
            'Success',
            `${uploadedFiles} file(s) uploaded successfully.`,
            'success'
        );
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}