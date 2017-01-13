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
