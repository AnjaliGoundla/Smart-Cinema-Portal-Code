import { LightningElement, api, wire } from 'lwc';

import getSubsidies
    from '@salesforce/apex/SubsidyDashboardController.getSubsidies';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

import { refreshApex }
    from '@salesforce/apex';

export default class SubsidyDashboard extends LightningElement {

    @api recordId;

    subsidies = [];
    wiredSubsidyResult;

    showRequestForm = false;

    @wire(getSubsidies)
    wiredSubsidies(result) {

        this.wiredSubsidyResult = result;

        const { data, error } = result;

        if (data) {

            this.subsidies = data.map(record => {

                return {
                    id: record.Id,

                    category:
                        record.Request_Type__c || 'Other',

                    requestedAmount:
                        record.Requested_Amount__c || 0,

                    approvedAmount:
                        record.Approved_Amount__c || 0,

                    status:
                        record.Status__c || 'Draft',

                    eligibility:
                        record.Eligibility__c || false
                };
            });

        } else if (error) {

            console.error(
                'Error loading subsidies',
                error
            );

            this.showToast(
                'Error',
                'Unable to load subsidy requests.',
                'error'
            );
        }
    }

    get subsidyGroups() {

        const groups = {};

        this.subsidies.forEach(subsidy => {

            if (!groups[subsidy.category]) {
                groups[subsidy.category] = [];
            }

            groups[subsidy.category].push(subsidy);
        });

        return Object.keys(groups).map(category => {

            return {
                category: category,
                records: groups[category]
            };
        });
    }

    get hasSubsidies() {
        return this.subsidies.length > 0;
    }

    get totalRequests() {
        return this.subsidies.length;
    }

    get pendingRequests() {

        return this.subsidies.filter(
            subsidy =>
                subsidy.status === 'Submitted' ||
                subsidy.status === 'Under Review'
        ).length;
    }

    get approvedRequests() {

        return this.subsidies.filter(
            subsidy =>
                subsidy.status === 'Approved' ||
                subsidy.status === 'Issued' ||
                subsidy.status === 'Disbursed'
        ).length;
    }

    handleShowRequestForm() {
        this.showRequestForm = true;
    }

    handleCancelRequest() {
        this.showRequestForm = false;
    }

    async handleRequestSuccess() {

        this.showRequestForm = false;

        this.showToast(
            'Success',
            'Subsidy request submitted successfully.',
            'success'
        );

        await refreshApex(
            this.wiredSubsidyResult
        );
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}