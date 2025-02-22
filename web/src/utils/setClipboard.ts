export const setClipboard = (value: string) => {
    const clipElem = document.createElement('textarea');
    clipElem.value = value;
    document.body.appendChild(clipElem);
    clipElem.select();
    document.execCommand('copy');
    document.body.removeChild(clipElem);
};