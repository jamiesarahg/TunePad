'use strict';


/**
 * Common HSV hue for all blocks in this category.
 */
//Blockly.Blocks.procedures.HUE = 290;

//Blockly.Blocks['tunepad_emit'] = {
Blockly.Blocks['tunepad_emit'] = {
  init: function() {
    this.appendValueInput('VALUE')
        .setCheck('String')
        .appendField('emit');
    this.setOutput(true, 'Number');
    this.setColour(160);
    this.setTooltip('Emits a sound.');
    this.setHelpUrl('');
  }
};
// working on adding generator function
Blockly.JavaScript['tunepad_emit'] = function(block) {
  // String or array length.
  var argument0 = Blockly.JavaScript.valueToCode(block, 'VALUE',
      Blockly.JavaScript.ORDER_FUNCTION_CALL) || '\'\'';
  console.log(argument0);
  return [argument0 + '.length', Blockly.JavaScript.ORDER_MEMBER];
};

Blockly.Blocks['tunepad_makesound'] = {
  init: function() {
    this.appendValueInput('VALUE')
        .setCheck('String')
        .appendField('make sound');
    this.setOutput(true, 'Number');
    this.setColour(260);
    this.setTooltip('Makes a sound.');
    this.setHelpUrl('');
  }
};

