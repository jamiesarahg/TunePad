/*
File for JS for Tune Pad Mock-up Node-beat style
*/
var canvas; //global variable to represent canvas
var audioCtx = new (window.AudioContext || window.webkitAudioContext)(); //global variable to represent the audio context

//golbal variables for the reaction functions for each color node
var red;
var green;
var purple;

//global arrays to keep track of existing nodes and emissions
var nodeTups = []; //array of nodes on the canvas. this array should be populated with arrays of format: [fabric canvas circle element of node, string of color of node]
var emissions = []; //array of emissions on the canvas (grey dots going between nodes). This array shoudl be populated with arrays of format: ([fabric canvas circle element of specific emission, dictionary with x&y element of start position, dictionary with x&y element of end position, current percentage from start to end, percentage to be moved each 10ms, array representing the node emission is aming to]);


$(document).ready(function () {
    canvas = new fabric.Canvas('canvas');

    setInterval(oneSecond, 10000); // emits a emission from black node every second
    setInterval(moveEmissions, 10); // moves all emissions every 10ms

    //Click functions for adding new nodes to the canvas of each color
    $('#green').click(function () {
        addNode(canvas, 'green');
    });
    $('#red').click(function () {
        addNode(canvas, 'red');
    });
    $('#purple').click(function () {
        addNode(canvas, 'purple');
    });

    //Click functions for updating the reaction functions for each color
    $('#updateRed').click(function () {
         red = new Function ('node', document.getElementById('redCode').value);
    })
    $('#updateGreen').click(function () {
        green = new Function('node', document.getElementById('greenCode').value);
    })
    $('#updatePurple').click(function () {
        purple = new Function('node', document.getElementById('purpleCode').value);
    })
    
   

    //initializs canvas with a black node
    addNode(canvas, 'black');

});

window.onload = function () {
    setUpBlockly();
}

/*
setUpBlockly
Inputs/Outputs: none
Puts blockly div in the blockly area defined in HTML
*/
function setUpBlockly() {
    var blocklyArea = document.getElementById('blocklyArea');
    var blocklyDiv = document.getElementById('blocklyDiv');
    blocklyCreateBlocks();
    var workspace = Blockly.inject(blocklyDiv,
        { toolbox: document.getElementById('toolbox') });
    var onresize = function (e) {
        console.log('resize');
        // Compute the absolute coordinates and dimensions of blocklyArea.
        var element = blocklyArea;
        var x = 0;
        var y = 0;
        do {
            x += element.offsetLeft;
            y += element.offsetTop;
            element = element.offsetParent;
        } while (element);
        // Position blocklyDiv over blocklyArea.
        blocklyDiv.style.left = x + 'px';
        blocklyDiv.style.top = y + 'px';
        blocklyDiv.style.width = blocklyArea.offsetWidth + 'px';
        blocklyDiv.style.height = blocklyArea.offsetHeight + 'px';
    };
    window.addEventListener('resize', onresize, false);
    onresize();
    Blockly.svgResize(workspace);

    $('#updateCode').click(function () {
        Blockly.JavaScript.addReservedWords('code');
        var code = Blockly.JavaScript.workspaceToCode(workspace);
        try {
            eval(code);
        } catch (e) {
            alert(e);
        }
    })

}

function blocklyCreateBlocks() {
    Blockly.Blocks['string_length'] = {
        init: function () {
            this.appendValueInput('VALUE')
                .setCheck('String')
                .appendField('length of');
            this.setOutput(true, 'Number');
            this.setColour(160);
            this.setTooltip('Returns number of letters in the provided text.');
            this.setHelpUrl('http://www.w3schools.com/jsref/jsref_length_string.asp');
        }
    };
    Blockly.Blocks['console_log_here'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("console log here");
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['define_red'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if red node hit");
            this.appendStatementInput("redCode")
                .setCheck(null)
                .appendField("do:");
            this.setInputsInline(false);
            this.setColour(0);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };

    Blockly.Blocks['make_sound'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("makeSound(")
                .appendField(new Blockly.FieldDropdown([["A3", "A3"], ["B3", "B3"], ["C4", "C4"], ["D4", "D4"], ["E4", "E4"], ["F4", "F4"], ["G4", "G4"]]), "note")
                .appendField(")");
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['emitblock'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("emit");
            this.appendValueInput("emit_from")
                .setCheck("node")
                .appendField("from");
            this.appendValueInput("emit_to")
                .setCheck("node")
                .appendField("to");
            this.setInputsInline(true);
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(65);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['node_variable'] = {
        init: function () {
            this.appendValueInput("node_name")
                .setCheck(null)
                .appendField(new Blockly.FieldTextInput("node"), "node_name");
            this.setOutput(true, "node");
            this.setColour(65);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['for_each_block'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("for each");
            this.appendValueInput("foreach_variable")
                .setCheck("node");
            this.appendDummyInput()
                .appendField("of all nodes:");
            this.appendStatementInput("foreach_statements")
                .setCheck(null)
                .appendField("do:");
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['if_node_color_block'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if ");
            this.appendValueInput("node")
                .setCheck("node");
            this.appendDummyInput()
                .appendField("color")
                .appendField(new Blockly.FieldDropdown([["=", "equal"], ["!=", "not_equal"]]), "operator")
                .appendField(new Blockly.FieldDropdown([["red", "red"], ["green", "green"], ["purple", "purple"], ["black", "black"]]), "colors");
            this.appendStatementInput("node_if_do")
                .setCheck(null)
                .appendField("do:");
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['if_node_distance_block'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if ");
            this.appendValueInput("node")
                .setCheck("node");
            this.appendDummyInput()
                .appendField("is")
                .appendField(new Blockly.FieldDropdown([["=", "equal"], ["!=", "not_equal"], [">", "greater_than"], [">=", "greater_or_equal"], ["<", "less_than"], ["<+", "less_or_equal"]]), "operator")
                .appendField(new Blockly.FieldNumber(0, 0), "distance")
                .appendField("pixels from the node hit:");
            this.appendStatementInput("node_if_do")
                .setCheck(null)
                .appendField("do:");
            this.setPreviousStatement(true, null);
            this.setNextStatement(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['list_of_all_nodes'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("list of all nodes");
            this.setOutput(true, null);
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['for_each'] = {
        init: function () {
            this.appendValueInput("for_each_list")
                .setCheck(null)
                .appendField("for each item")
                .appendField(new Blockly.FieldVariable("node"), "for_each_variable")
                .appendField("in list");
            this.appendStatementInput("for_each_do")
                .setCheck(null)
                .appendField("do");
            this.setOutput(true, null);
            this.setColour(65);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };

    //Generators
    Blockly.JavaScript['console_log_here'] = function (block) {
        var code = 'console.log("here")';
        return code;
    };
    Blockly.JavaScript['define_red'] = function (block) {
        var statements_redcode = Blockly.JavaScript.statementToCode(block, 'redCode');
        red = new Function('node', statements_redcode);

    };
    Blockly.JavaScript['make_sound'] = function (block) {
        var dropdown_note = block.getFieldValue('note');
        var code = 'makeSound("' + dropdown_note + '")';
        return code;
    };
    Blockly.JavaScript['emitblock'] = function (block) {
        var value_emit_from = Blockly.JavaScript.valueToCode(block, 'emit_from', Blockly.JavaScript.ORDER_ATOMIC);
        var value_emit_to = Blockly.JavaScript.valueToCode(block, 'emit_to', Blockly.JavaScript.ORDER_ATOMIC);
        var code = 'emit('+value_emit_from+','+value_emit_to + ')';
        return code;
    };
    Blockly.JavaScript['node_variable'] = function (block) {
        var text_node_name = block.getFieldValue('node_name');
        var value_node_name = Blockly.JavaScript.valueToCode(block, 'node_name', Blockly.JavaScript.ORDER_ATOMIC);
        // TODO: Assemble JavaScript into code variable.
        var code = value_node_name;
        console.log(code);
        // TODO: Change ORDER_NONE to the correct strength.
        return [code, Blockly.JavaScript.ORDER_NONE];
    };
    Blockly.JavaScript['for_each_block'] = function (block) {
        var value_foreach_variable = Blockly.JavaScript.variableDB_.getName(block.getFieldValue('foreach_variable'), Blockly.Variables.NAME_TYPE);
        var statements_foreach_statements = Blockly.JavaScript.statementToCode(block, 'foreach_statements');
        var code = 'nodeTups.forEach(function (' + value_foreach_variable + ') {' + statements_foreach_statements + '}})';
        console.log(code);
        return code;
    };

    Blockly.JavaScript['if_node_color_block'] = function(block) {
        var value_node = Blockly.JavaScript.valueToCode(block, 'node', Blockly.JavaScript.ORDER_ATOMIC);
        var dropdown_operator = block.getFieldValue('operator');
        var dropdown_colors = block.getFieldValue('colors');
        var statements_node_if_do = Blockly.JavaScript.statementToCode(block, 'node_if_do');
        var code = 'if ' + value_node[1] + dropdown_operator + dropdown_colors + ':' + statements_node_if_do;
        return code;
    };
    Blockly.JavaScript['if_node_distance_block'] = function (block) {
        var value_node = Blockly.JavaScript.valueToCode(block, 'node', Blockly.JavaScript.ORDER_ATOMIC);
        var dropdown_operator = block.getFieldValue('operator');
        var number_distance = block.getFieldValue('distance');
        var statements_node_if_do = Blockly.JavaScript.statementToCode(block, 'node_if_do');
        var code = 'if ' + value_node[1] + dropdown_operator + number_distance + ':' + statements_node_if_do;
        return code;
    };
    Blockly.JavaScript['list_of_all_nodes'] = function (block) {
        // TODO: Assemble JavaScript into code variable.
        var code = nodeTups;
        // TODO: Change ORDER_NONE to the correct strength.
        return [code, Blockly.JavaScript.ORDER_NONE];
    };
    Blockly.JavaScript['for_each'] = function (block) {
        var variable0 = Blockly.JavaScript.variableDB_.getName(block.getFieldValue('for_each_variable'), Blockly.Variables.NAME_TYPE);
        var argument0 = Blockly.JavaScript.valueToCode(block, 'for_each_list', Blockly.JavaScript.ORDER_ATOMIC);
        var branch = Blockly.JavaScript.statementToCode(block, 'for_each_do');
        branch = Blockly.JavaScript.addLoopTrap(branch, block.id);
        var code = '';
        var listVar = argument0;
        if (!argument0.match(/^\w+$/)) {
            listVar = Blockly.JavaScript.variableDB_.getDistinctName(
                variable0 + '_list', Blockly.Variables.NAME_TYPE);
            code += 'var ' + listVar + ' = ' + argument0 + ';\n';
        }
        var indexVar = Blockly.JavaScript.variableDB_.getDistinctName(
            variable0 + '_index', Blockly.Variables.NAME_TYPE);
        branch = Blockly.JavaScript.INDENT + variable0 + ' = ' +
            listVar + '[' + indexVar + '];\n' + branch;
        code += 'for (var ' + indexVar + ' in ' + listVar + ') {\n' + branch + '}\n';
        return code;
    };

    
}
/*
 moveEmissions
 inputs: none
 outputs: none
 moves each emission by respective percentage of distance from their start position to their end position
    if an emission has reached the end function, remove emission from the board and call the reaction function for the respective node
 updates emissions array
*/
function moveEmissions() {
    emissions.forEach(function (emission) {
        //checks to see if emission reached end
        if (emission[3] >= 100) {
            canvas.remove(emission[0]);
            var index = emissions.indexOf(emission);
            emissions.splice(index, 1);
            pingNode(emission[5]);
        }
        //moves remainder of emissions
        else {
            emission[3] += emission[4];
            var newLocation = getLineXYatPercent(emission[1], emission[2], emission[3])
            emission[0].left = newLocation.x;
            emission[0].top = newLocation.y;
        }
    })
    canvas.renderAll();
}
/*
addNode
inputs: canvas element, string of color for node to add
outputs: none
adds a node to the canvas at (100,100) of input color
appends to nodeTups array
*/
function addNode(canvas, color) {
    var circle = new fabric.Circle({ radius: 10, fill: color, top: 100, left: 100 })
    circle.hasControls = false;
    nodeTups.push([circle, color]);
    canvas.add(circle);
}

/*
oneSecond
inputs: none
outputs: none
If black nodes are on the board, emit and emission for every other node
*/
function oneSecond() {
    nodeTups.forEach(function (nodeTup) {
        if (nodeTup[1] == 'black') {
            nodeTups.forEach(function (endNodeTup) {
                if (endNodeTup[1] != 'black') {
                    emit(nodeTup[0], endNodeTup);
                }
            })
            //black(nodeTup[0]);
        }
    })
}


/*
emit
inputs: node: fabric element of node emitting from, endNodeTup: array of node in NodeTup form of destination node
outputs: none
starts an emission from node to node of endNodeTup
updates emissions array
*/
function emit(node, endNodeTup) {
    if (node !== endNodeTup[0]) {
        var start = { x: parseFloat(node.left) + parseFloat(node.radius), y: parseFloat(node.top) + parseFloat(node.radius) };
        var end = { x: parseFloat(endNodeTup[0].left) + parseFloat(endNodeTup[0].radius), y: parseFloat(endNodeTup[0].top) + parseFloat(endNodeTup[0].radius) };
        var d = Math.sqrt(Math.pow((end.x - start.x), 2) + Math.pow((end.y - start.y), 2));
        var perc = 100.0 / d; //looks at distance from start to end position and decides what percentage of the distance the emission should move every 10ms

        var emission = new fabric.Circle({ radius: 3, fill: 'grey', top: start.y, left: start.x });
        canvas.add(emission);
        emissions.push([emission, start, end, 0, perc, endNodeTup]);
    }  
}
/*
getLineXYatPercent
inputs: startPt: dictionary with x&y representing start position, endPt: dictionary with x&y representing end position, percentage of line that emission should be at
outputs: dictionary with x&y representing percentage between start and finish
calculates the position on a line from startPt to endPT of the given percent
*/
function getLineXYatPercent(startPt, endPt, percent) {
    var dx = endPt.x - startPt.x;
    var dy = endPt.y - startPt.y;
    var X = (startPt.x + dx * percent / 100);
    var Y = (startPt.y + dy * percent/100);
    return ({ x: X, y: Y });
}

/*
pingNode
inputs: nodeTup: array of fabric node and color of node
outputs: none
Calls reaction function for given node
*/
function pingNode(nodeTup){
    var color = nodeTup[1];
    if (color == 'black') {
        black(nodeTup[0]);
    }
    if (color == 'red') {
        red(nodeTup[0]);
    }
    if (color == 'green') {
        green(nodeTup[0])
    }
    if (color == 'purple') {
        purple(nodeTup[0])
    }
}

/*
makeSound(note)
inputs: note: string of a note
outputs: none
plays the sound of given note string
*/
function makeSound(note) {
    var oscillator = audioCtx.createOscillator();
    var gainNode = audioCtx.createGain();
    lettersToFrequency = {'A3': 220.00, 'B3': 246.94, 'C4': 261.63, 'D4': 293.66, 'E4':329.63, 'F4': 349.23, 'G4':392.00}

    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);


    var initialFreq = lettersToFrequency[note];
    oscillator.type = 'sine'; // sine wave — other values are 'square', 'sawtooth', 'triangle' and 'custom'
    oscillator.frequency.value = initialFreq; // value in hertz
    oscillator.start();
    oscillator.stop(audioCtx.currentTime + .2);
}

/*
black
inputs:node
function of what a black node should do if it gets hit. Currently nothing
*/
function black(node) {

}
