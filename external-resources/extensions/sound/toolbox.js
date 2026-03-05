/* eslint-disable func-style */
/* eslint-disable max-len */
/* eslint-disable require-jsdoc */
function registerToolboxs () {
    return `
<category name="%{BKY_TUBITV2SOUNDSENSOR_CATEGORY}" id="TUBITV2SOUNDSENSOR_CATEGORY" colour="#4CE45F" secondaryColour="#4CE45F" iconURI="../external-resources/extensions/default_icon.svg">
    
    <block type="tubitv2sonudsensor_init" id="tubitv2sonudsensor_init"></block>
    <block type="tubitv2sonudsensor_read" id="tubitv2sonudsensor_read"></block>
    
</category>`;
}

exports = registerToolboxs;
