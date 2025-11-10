import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export function showNotification(title, message, variant) {
    let evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    dispatchEvent(evt);
}

export function showError(response) {
    var messages = collectError(response);
    messages.forEach(function (message) {
        showNotification('Error', message, 'error');
    });
}

export function collectError(response) {
    var messages = [];
    var errors;
    if (typeof response === 'string' || !response.body) {
        messages.push(response.toString());
    } else if (response.body.message) {
        messages.push(response.body.message);
    } else {
        errors = response.body.pageErrors;
    }

    errors && errors.forEach(function (error) {
        messages.push(error.statusCode + ' : ' + error.message);
    });

    if (messages.length === 0) {
        messages.push(unexpectedError);
    }
    return messages;
}