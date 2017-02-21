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

var numSeconds = 10000;

var interval;

var workspace;  //this is the main Blockly workspace

$(document).ready(function () {
    canvas = new fabric.Canvas('canvas');
    canvas.setHeight(window.innerHeight / 2); //set the canvas to be half of the height of the screen
    canvas.setWidth(window.innerWidth); // set the canvas to be the entire width of the screen
    canvas.selection = false; // disable group selection
    interval = setInterval(tenSeconds, numSeconds); // emits a emission from black node every second
    setInterval(moveEmissions, 10); // moves all emissions every 10ms

    $('#seconds').val(10);
    $('#seconds').on('change',onBlocklyChange);

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
    
    var trashCan = new Image();
    trashCan.src = 'images/trash.png';
    trashCan.onload = function () {
        var image = new fabric.Image(trashCan);
        image.left = 10;
        image.top = 260;
        image.hasControls = false;
        image.lockMovementX = true;
        image.lockMovementY = true;
        image.selectable = false;
        canvas.add(image);

        //initializs canvas with a black node
        addNode(canvas, 'black');
    }

    // sets variable when mouse is down
    canvas.on('mouse:down', function (options) {
        mousedown = true;
    });
    // releases variable when mouse is up
    canvas.on('mouse:up', function (options) {
        mousedown = false;
        if (options.target) {
            onChange(options);
        }
    });
    // if a node is moved, then any emissions going to that node will fade out.
    // this changes the end goal of the particle to not be a node but to be 'fade'
    canvas.on('object:modified', function (options) {
        emissions.forEach(function (emission) {
            if (options.target == emission[5][0]) {
                emission[5] = 'fade';
            }
        })
    // if a node is dragged off of the screen then it is deleted.
        nodeTups.forEach(function (nodeTup) {
            if (0 > nodeTup[0].left || nodeTup[0].left > window.innerWidth || 0 > nodeTup[0].top || nodeTup[0].top > window.innerHeight/2) {
                    nodeTup[0].remove();   
                    var index = nodeTups.indexOf(nodeTup);
                    nodeTups.splice(index, 1);
                }
            })
    })
});

// sets up blockly interface and web audio
window.onload = function () {
    setUpBlockly();
    setUpSound();
}

// onChange
// function for mouseup on the fabric canvas if something has changed
// inputs: options from the change event
// output: none
function onChange(options) {
    // Checks if item moved overlaps with the trash can object. If so, deletes node.
    options.target.setCoords();
    //TODO
    //must find better way to identify trashcan
    trashCan = canvas.getObjects()[0];
    if (options.target != trashCan && options.target._objects[0].fill != 'black') {
        var intersects = options.target.intersectsWithObject(trashCan);
        if (intersects) {
            //nodes are now groups, so have to delete the entire group
            if (canvas.getActiveGroup()) {
                canvas.getActiveGroup().forEachObject(function (o) { canvas.remove(o) });
                canvas.discardActiveGroup().renderAll();
            } else {
                canvas.remove(canvas.getActiveObject());
            }
            // also must take node out of nodeTups array
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
function setUpBlockly(canvas) {
    var blocklyArea = document.getElementById('blocklyArea');
    var blocklyDiv = document.getElementById('blocklyDiv');

    blocklyCreateBlocks();
    workspace = Blockly.inject(blocklyDiv,
        { toolbox: document.getElementById('toolbox') });
    workspace.addChangeListener(onBlocklyChange);
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
        document.getElementById('updateCodeBW').style.display = 'inherit';
        document.getElementById('updateCode').style.display = 'none';
        var code = Blockly.JavaScript.workspaceToCode(workspace);

        clearInterval(interval);
        numSeconds = (document.getElementById('seconds').value)*1000;
        interval = setInterval(tenSeconds, numSeconds);
        console.log(numSeconds);

        try {
            eval(code);
        } catch (e) {
            alert(e);
        }
    })
}
/*
onBlocklyChange
inputs: change event
outputs: none
makes the update button in color when something has changed in blockly
*/
function onBlocklyChange(event) {
    if (event.type == "create") {
        var blockId = event.blockId;
        if (blockId != null) disableBlock(blockId, true);   
    }
    if (event.type == "delete") {
        var blockId = event.blockId;
        if (blockId != null) disableBlock(blockId, false); 
    }

    document.getElementById('updateCodeBW').style.display = 'none';
    document.getElementById('updateCode').style.display = 'inherit';
}

function disableBlock(blockID, disabled) {
    var block = document.getElementById(blockID);
    if (block != null) {
        block.setAttribute("disabled", disabled);
        workspace.updateToolbox(document.getElementById('toolbox'));
    }

}

/*
dynamicOptions
inputs: none
output: list of options for dropdown menu of the nodes on the board
Creates an array of arrays. In the array is a string of the number of each node on the board and the same string a second time
This is the dropdown object and then the name of the dropdown object for blockly
*/
function dynamicOptions() {
    var options = [];
    var nodeLen = nodeTups.length;
    nodeTups.forEach(function (nodeTup) {
        options.push([String(nodeTup[2]), String(nodeTup[2])]) //nodeTup[2] is the number of each node
    })
    return options;
}
/*
blocklyCreateBlocks
inputs: none
output: none
defines my custom blocks, both the output JS and how they should look
*/
function blocklyCreateBlocks() {
    Blockly.Blocks['define_red'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("if red node is hit");
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
                .appendField("if green node is hit");
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
                .appendField("if purple node is hit");
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
                .appendField("play the note: ")
                .appendField(new Blockly.FieldDropdown([["A3", "A3"], ["B3", "B3"], ["C4", "C4"], ["D4", "D4"], ["E4", "E4"], ["F4", "F4"], ["G4", "G4"]]), "note")
                .appendField("");
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
                .appendField("send dot ");
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
                .appendField("this node");
            this.setOutput(true, "node");
            this.setColour(65);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };
    Blockly.Blocks['node_variable'] = {
        init: function () {
            //this.appendValueInput("node_name")
            this.appendDummyInput()
                //.setCheck(null)
                .appendField(new Blockly.FieldTextInput("node_on_the_board"), "node_name");
            this.setOutput(true, "node");
            this.setColour(65);
            this.setTooltip('');
            this.setHelpUrl('');
        }
    };

    //var dropdown = new Blockly.FieldDropdown(dynamicOptions);
    Blockly.Blocks['individual_node'] = {
        init: function () {
            this.appendDummyInput()
                .appendField("node")
                .appendField(new Blockly.FieldDropdown(dynamicOptions), 'node_number');
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
                .appendField("");
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
                .appendField("if the ");
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
                .appendField("if the ");
            this.appendValueInput("node")
                .setCheck("node");
            this.appendDummyInput()
                .appendField("is")
                .appendField(new Blockly.FieldDropdown([ [">", "greater_than"], [">=", "greater_or_equal"], ["<", "less_than"], ["<+", "less_or_equal"], ["=", "equal"], ["!=", "not_equal"]]), "operator")
                .appendField(new Blockly.FieldNumber(0, 0), "distance")
                .appendField("pixels from this node");
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
        var code = 'emit(' + value_emit_from + ',' + value_emit_to + ');';
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
        var code = 'nodeTups.forEach(function ' + value_foreach_variable + ' {' + statements_foreach_statements + '});';
        return code;
    };
    Blockly.JavaScript['individual_node'] =  function (block) {
        var dropdown_node_number = block.getFieldValue('node_number');
        var index = null;
        nodeTups.forEach(function (nodeTup) {
            if (String(nodeTup[2]) == String(dropdown_node_number)) {
                index = nodeTups.indexOf(nodeTup);
            }
        });
        var code = 'nodeTups['+index+']';
        return [String(code), Blockly.JavaScript.ORDER_NONE];
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
        var code = 'if ( findDistance(' + value_node.slice(1, -1) + '[0], self[0]) ' + operator + ' ' + number_distance + ') {' + statements_node_if_do + '}';
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
    // finds the current highest node number
    var nodeNumber = -1;   
    nodeTups.forEach(function (node) {
        nodeNumber = (node[2] > nodeNumber) ? node[2] : nodeNumber;
    });
    nodeNumber = nodeNumber + 1;
    // picks random location on canvas to put the new node
    var left = getRandomInt(canvasArea.style.left.substring(0, canvasArea.style.left.length - 2) + 20, canvasArea.style.left.substring(0, canvasArea.style.left.length - 2) + canvasArea.style.width.substring(0, canvasArea.style.width.length - 2) - 20);
    var top = getRandomInt(canvasArea.style.top.substring(0, canvasArea.style.top.length - 2) + 20, canvasArea.style.top.substring(0, canvasArea.style.top.length - 2) + canvasArea.style.height.substring(0, canvasArea.style.height.length - 2) - 50);
    //creates fabric circle for node and fabric text of the node number
    var c = new fabric.Circle({ radius: 15, fill: color, top: top, left: left });
    var t = new fabric.Text(String(nodeNumber), { left: left+10, top: top+2, fontSize: 24, fill: 'white' });
    // creates a group of the circle and text
    var g = new fabric.Group([c, t], {});
    g.hasControls = false;
    g.lockScalingX = true;
    g.lockScalingY = true;
    // adds new node group to nodeTups array
    nodeTups.push([g, color, nodeNumber]);
    //adds new node group to canvas
    canvas.add(g);
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
                        emit(nodeTup, endNodeTup);
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
function findDistance(nodeA, nodeB) {
    var start = { x: parseFloat(nodeA.left), y: parseFloat(nodeA.top)  };
    var end = { x: parseFloat(nodeB.left) , y: parseFloat(nodeB.top)  };
    return Math.sqrt(Math.pow((end.x - start.x), 2) + Math.pow((end.y - start.y), 2));
}

/*
emit
inputs: nodeTup: array of node in NodeTup form of origin node, endNodeTup: array of node in NodeTup form of destination node
outputs: none
starts an emission from node to node of endNodeTup
updates emissions array
*/
function emit(nodeTup, endNodeTup) {
    // checks how many particles are on the board. If more than 800, alert user and erase all particles
    if (emissions.length > 800) {
        emissions.forEach(function (emission) {
            canvas.remove(emission[0]);
        });
        emissions = [];
        alert('IT EXPLOADED!');
    }
    //only sends particle if the start node and end node are not the same
    if (nodeTup[0] !== endNodeTup[0]) {
        //identifies circle element of node group
        startDot = nodeTup[0]._objects[0] 
        endDot = endNodeTup[0]._objects[0]

        var start = { x: parseFloat(nodeTup[0].left) + parseFloat(startDot.radius), y: parseFloat(nodeTup[0].top) + parseFloat(startDot.radius) };
        var end = { x: parseFloat(endNodeTup[0].left) + parseFloat(endDot.radius), y: parseFloat(endNodeTup[0].top) + parseFloat(endDot.radius) };
        var d = findDistance(nodeTup[0], endNodeTup[0]);

        var perc = 100.0 / d; //looks at distance from start to end position and decides what percentage of the distance the emission should move every 10ms
        var emission = new fabric.Circle({ radius: 3, fill: 'black', top: start.y, left: start.x });
        emission.hasControls = false;
        emission.lockMovementX = true;
        emission.lockMovementY = true;
        emission.selectable = false;
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
function pingNode(nodeTup, distance){
    var color = nodeTup[1];
    if (color == 'black') {
        black(nodeTup, distance);
    }
    if (color == 'red') {
        red(nodeTup, distance);
    }
    if (color == 'green') {
        green(nodeTup, distance)
    }
    if (color == 'purple') {
        purple(nodeTup, distance)
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
makeSound
inputs: note: string of a note, volume: percentage of volume that should be played from 0-1. Loudest is 1
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
