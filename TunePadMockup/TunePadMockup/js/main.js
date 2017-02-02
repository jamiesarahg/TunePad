/*
File for JS for Tune Pad Mock-up Node-beat style
*/

//Block factory: https://blockly-demo.appspot.com/static/demos/blockfactory/index.html#9hmdyx
var canvas; //global variable to represent canvas
var audioCtx = new (window.AudioContext || window.webkitAudioContext)(); //global variable to represent the audio context

//golbal variables for the reaction functions for each color node
var red;
var green;
var purple;

//global arrays to keep track of existing nodes and emissions
var nodeTups = []; //array of nodes on the canvas. this array should be populated with arrays of format: [fabric canvas circle element of node, string of color of node]
var emissions = []; //array of emissions on the canvas (grey dots going between nodes). This array shoudl be populated with arrays of format: ([fabric canvas circle element of specific emission, dictionary with x&y element of start position, dictionary with x&y element of end position, current percentage from start to end, percentage to be moved each 10ms, array representing the node emission is aming to]);

var sounds = {};

var mousedown = false;


$(document).ready(function () {
    canvas = new fabric.Canvas('canvas');
    setInterval(tenSeconds, 10000); // emits a emission from black node every second
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

    // Initial functions for nodes
    red = new Function(['self', 'distance'], '');
    green = new Function(['self', 'distance'], '');
    purple = new Function(['self', 'distance'], '');
    
   
    //initializs canvas with a black node
    addNode(canvas, 'black');

    canvas.on('mouse:down', function (options) {
        mousedown = true;
    });
    canvas.on('mouse:up', function (options) {
        mousedown = false;
        if (options.target) {
            onChange(options);
        }
    });
    canvas.on('object:modified', function (options) {
        console.log('mod')
        emissions.forEach(function (emission) {
            console.log(options.target)
            console.log(emission[5])
            if (options.target == emission[5][0]) {
                emission[5] = 'fade';
                console.log('here')
            }
        })
    })

    var trashCan = new Image();
    trashCan.src = 'images/trash.png';
    trashCan.onload = function () {
        var image = new fabric.Image(trashCan);
        image.left = 10;
        image.top = 430;
        image.hasControls = false;
        image.lockMovementX = true;
        image.lockMovementY = true;
        image.selectable = false;
        canvas.add(image);
    }
});

window.onload = function () {
    setUpBlockly();
    setUpSound();

}

function onChange(options) {
    options.target.setCoords();
    //TODO
    //must find better way to identify trashcan
    trashCan = canvas.getObjects()[1];
    if (options.target != trashCan) {
        var intersects = options.target.intersectsWithObject(trashCan);
        if (intersects) {
            options.target.remove();
            nodeTups.forEach(function (nodeTup) {
                if (nodeTup[0] == options.target) {
                    var index = nodeTups.indexOf(nodeTup);
                    nodeTups.splice(index, 1);
                }
            });
        }
    }
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
    Blockly.Blocks['define_green'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if green node hit");
            this.appendStatementInput("greenCode")
                .setCheck(null)
                .appendField("do:");
            this.setInputsInline(false);
            this.setColour(120);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['define_purple'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if purple node hit");
            this.appendStatementInput("purpleCode")
                .setCheck(null)
                .appendField("do:");
            this.setInputsInline(false);
            this.setColour(260);
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
            this.setColour(230);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['self_node'] = {
        init: function() {
            this.appendDummyInput()
                .appendField("node: 'self'");
            this.setOutput(true, "node");
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
                .appendField(new Blockly.FieldDropdown([ [">", "greater_than"], [">=", "greater_or_equal"], ["<", "less_than"], ["<+", "less_or_equal"], ["=", "equal"], ["!=", "not_equal"]]), "operator")
                .appendField(new Blockly.FieldNumber(0, 0), "distance")
                .appendField("pixels from self:");
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


    //Generators
    Blockly.JavaScript['define_red'] = function (block) {
        var statements_redcode = Blockly.JavaScript.statementToCode(block, 'redCode');
        red = new Function(['self', 'distance'], statements_redcode);
    };
    Blockly.JavaScript['define_green'] = function (block) {
        var statements_greencode = Blockly.JavaScript.statementToCode(block, 'greenCode');
        green = new Function(['self', 'distance'], statements_greencode);
    };
    Blockly.JavaScript['define_purple'] = function (block) {
        var statements_purplecode = Blockly.JavaScript.statementToCode(block, 'purpleCode');
        purple = new Function(['self', 'distance'], statements_purplecode);

    };
    Blockly.JavaScript['make_sound'] = function (block) {
        var dropdown_note = block.getFieldValue('note');
        var code = 'makeSound("' + dropdown_note + '", distance);';

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
        var code = text_node_name;
        return [code, Blockly.JavaScript.ORDER_NONE];
    };
    Blockly.JavaScript['self_node'] = function (block) {
        var code = 'self';
        return [code, Blockly.JavaScript.ORDER_NONE];
    };
    Blockly.JavaScript['for_each_block'] = function (block) {
        var value_foreach_variable = Blockly.JavaScript.valueToCode(block, 'foreach_variable', Blockly.JavaScript.ORDER_ATOMIC);
        var statements_foreach_statements = Blockly.JavaScript.statementToCode(block, 'foreach_statements');
        var code = 'nodeTups.forEach(function ' + value_foreach_variable + ' {' + statements_foreach_statements + '})';
        return code;
    };

    Blockly.JavaScript['if_node_color_block'] = function (block) {
        var OPERATORS = {
            'equal': '==',
            'not_equal': '!=',
          };
        var operator = OPERATORS[block.getFieldValue('operator')];
        var dropdown_colors = block.getFieldValue('colors');
        var value_node = Blockly.JavaScript.valueToCode(block, 'node', Blockly.JavaScript.ORDER_ATOMIC);
        var statements_node_if_do = Blockly.JavaScript.statementToCode(block, 'node_if_do');
        var code = 'if ' + '(' + value_node.slice(1, -1) + '[1] '  + operator + ' "' + dropdown_colors + '") {' + statements_node_if_do + '}';
        return code;
    };
    Blockly.JavaScript['if_node_distance_block'] = function (block) {
        var OPERATORS = {
            'equal': '==',
            'not_equal': '!=',
            'less_than': '<',
            'less_than_or_equal': '<=',
            'greater_than': '>',
            'greater_than_or_equal': '>='
        };
        var operator = OPERATORS[block.getFieldValue('operator')];
        var value_node = Blockly.JavaScript.valueToCode(block, 'node', Blockly.JavaScript.ORDER_ATOMIC);
        var number_distance = block.getFieldValue('distance');
        var statements_node_if_do = Blockly.JavaScript.statementToCode(block, 'node_if_do');
        var code = 'if ( distance(' +  value_node.slice(1, -1) + '[0], self) ' + operator + ' ' + number_distance + ') {' + statements_node_if_do + '}';
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
    if (!mousedown) {
        emissions.forEach(function (emission) {
            var opacity = 1 - (1 / (500 * emission[4]) * emission[3]);
            //checks to see if emission reached end
            if (emission[3] >= 100 & emission[5] != 'fade') {
                canvas.remove(emission[0]);
                var index = emissions.indexOf(emission);
                emissions.splice(index, 1);
                pingNode(emission[5], opacity);
                //document.getElementById('emissionsCount').innerHTML = 'Number of Emissions: \n' + emissions.length;
            }
                //moves remainder of emissions
            else {
                emission[3] += emission[4];
                var newLocation = getLineXYatPercent(emission[1], emission[2], emission[3])
                emission[0].left = newLocation.x;
                emission[0].top = newLocation.y;
                if (opacity < 0) {
                    canvas.remove(emission[0]);
                    var index = emissions.indexOf(emission);
                    emissions.splice(index, 1);
                }
                else {
                    emission[0].setOpacity(opacity);
                }
            }
        })
        canvas.renderAll();
    }
}
/*
addNode
inputs: canvas element, string of color for node to add
outputs: none
adds a node to the canvas at (100,100) of input color
appends to nodeTups array
*/
function addNode(canvas, color) {
    canvasArea = document.getElementById('canvas');
    var left = getRandomInt(canvasArea.style.left.substring(0, canvasArea.style.left.length - 2) + 20, canvasArea.style.left.substring(0, canvasArea.style.left.length - 2) + canvasArea.style.width.substring(0, canvasArea.style.width.length - 2) - 20);
    var top = getRandomInt(canvasArea.style.top.substring(0, canvasArea.style.top.length - 2) + 20, canvasArea.style.top.substring(0, canvasArea.style.top.length - 2) + canvasArea.style.height.substring(0, canvasArea.style.height.length - 2) - 50);

    console.log(Math.floor(canvasArea.style.left.substring(0, canvasArea.style.left.length - 2)));
    var circle = new fabric.Circle({ radius: 10, fill: color, top: top, left: left });
    circle.hasControls = false;
    circle.lockScalingX = true;
    circle.lockScalingY = true;
    nodeTups.push([circle, color]);
    canvas.add(circle);
}
/*
getRandomInt
inputs: two integers, one the minimum and one the maximum
output: random integer between the minimum and maximum.
*/
function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min)) + min;
}

/*
tenSeconds
inputs: none
outputs: none
If black nodes are on the board, emit and emission for every other node
*/
function tenSeconds() {
    if (!mousedown) {
        nodeTups.forEach(function (nodeTup) {
            if (nodeTup[1] == 'black') {
                nodeTups.forEach(function (endNodeTup) {
                    if (endNodeTup[1] != 'black') {
                        emit(nodeTup[0], endNodeTup);
                    }
                })
            }
        })
    }
    
}

/*
distance_between_two_nodes
inputs: nodeA, nodeB
outputs: distance in pixels
*/
function distance(nodeA, nodeB) {
    var start = { x: parseFloat(nodeA.left) + parseFloat(nodeA.radius), y: parseFloat(nodeA.top) + parseFloat(nodeA.radius) };
    var end = { x: parseFloat(nodeB.left) + parseFloat(nodeB.radius), y: parseFloat(nodeB.top) + parseFloat(nodeB.radius) };
    return Math.sqrt(Math.pow((end.x - start.x), 2) + Math.pow((end.y - start.y), 2));
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
        var d = distance(node, endNodeTup[0]);
        var perc = 100.0 / d; //looks at distance from start to end position and decides what percentage of the distance the emission should move every 10ms
        var emission = new fabric.Circle({ radius: 3, fill: 'black', top: start.y, left: start.x });
        canvas.add(emission);
        emissions.push([emission, start, end, 0, perc, endNodeTup]);
        //document.getElementById('emissionsCount').innerHTML = 'Number of Emissions:' + emissions.length;
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
function pingNode(nodeTup, distance){
    var color = nodeTup[1];
    if (color == 'black') {
        black(nodeTup[0], distance);
    }
    if (color == 'red') {
        red(nodeTup[0], distance);
    }
    if (color == 'green') {
        green(nodeTup[0], distance)
    }
    if (color == 'purple') {
        purple(nodeTup[0], distance)
    }
}
/*
setUpSound
inputs: none
outputs: none
loads sound directory.
*/
function setUpSound() {
    notes = ['A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4']

    notes.forEach(function (note) {
        var sound;
        var getSound = new XMLHttpRequest(); // Load the Sound with XMLHttpRequest
        getSound.open("GET", "Marimba_Sounds/"+ note + "_Marimba.wav", true); // Path to Audio File
        getSound.responseType = "arraybuffer"; // Read as Binary Data
        getSound.onload = function () {
            audioCtx.decodeAudioData(getSound.response, function (buffer) {
                sound = buffer; // Decode the Audio Data and Store it in a Variable
                sounds[note] = sound;
            });
        }
        getSound.send(); // Send the Request and Load the File
    })
}
/*
makeSound(note)
inputs: note: string of a note
outputs: none
plays the sound of given note string
*/
function makeSound(note, volume) {
    sound = sounds[note];
    var playSound = audioCtx.createBufferSource(); // Declare a New Sound
    playSound.buffer = sound; // Attatch our Audio Data as it's Buffer
    var gainNode = audioCtx.createGain();
    playSound.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    if (isNaN(volume)) { volume = 1;}
    gainNode.gain.value = volume;
    playSound.start(0); // Play the Sound Immediately
}

/*
black
inputs:node
function of what a black node should do if it gets hit. Currently nothing
*/
function black(node, distance) {
}
