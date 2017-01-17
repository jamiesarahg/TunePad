// JavaScript source code
//Blockly.JavaScript['console_log_here'] = function (block) {
//    var code = 'console.log("here")';
//    return code;
//};
//Blockly.JavaScript['define_red'] = function(block) {
//    var statements_redcode = Blockly.JavaScript.statementToCode(block, 'redCode');
//    console.log(statements_redcode);
//    // TODO: Assemble JavaScript into code variable.
//    var code = "red = new Function( 'node', " + statements_redcode + ");\n";
//    console.log(code);
//    return code;
//};

//var n = 0;
//var code = '', branchCode, conditionCode;
//do {
//    conditionCode = Blockly.JavaScript.valueToCode(block, 'IF' + n,
//      Blockly.JavaScript.ORDER_NONE) || 'false';
//    branchCode = Blockly.JavaScript.statementToCode(block, 'DO' + n);
//    code += (n > 0 ? ' else ' : '') +
//        'if (' + conditionCode + ') {\n' + branchCode + '}';

//    ++n;
//} while (block.getInput('IF' + n));

//if (block.getInput('ELSE')) {
//    branchCode = Blockly.JavaScript.statementToCode(block, 'ELSE');
//    code += ' else {\n' + branchCode + '}';
//}
//return code + '\n';
//};