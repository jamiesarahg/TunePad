// Your code here!
var canvas;
var audioCtx = new (window.AudioContext || window.webkitAudioContext)();

var red;
var green;

var nodeTups = [];
var canvas;
var emissions = [];


$(document).ready(function () {
    canvas = new fabric.Canvas('canvas');

    setInterval(oneSecond, 10000);
    setInterval(moveEmissions, 10);

    $('#green').click(function () {
        addNode(canvas, 'green');
    });
    $('#red').click(function () {
        addNode(canvas, 'red');
    });
    $('#purple').click(function () {
        addNode(canvas, 'purple');
    });
    $('#updateRed').click(function () {
         red = new Function ('node', document.getElementById('redCode').value);
    })
    $('#updateGreen').click(function () {
        green = new Function('node', document.getElementById('greenCode').value);
    })
    $('#updatePurple').click(function () {
        purple = new Function('node', document.getElementById('purpleCode').value);
    })

    canvas.on('object:modified', function (options) {
        paths.forEach(function (path) {
            canvas.remove(path);
        });

    });
    canvas.on('object:')
    addNode(canvas, 'black');

});

window.onload = function () {
    var redStartText = "console.log('red');\nmakeSound('C4');"
    document.getElementById('redCode').value = redStartText;
    red = new Function('node', document.getElementById('redCode').value);
    
    var greenStartText = "nodeTups.forEach(function (endNodeTup) {\n\temit(node, endNodeTup);\n})"
    document.getElementById('greenCode').value = greenStartText;
    green = new Function('node', document.getElementById('greenCode').value);

    var purpleStartText = "nodeTups.forEach(function (endNodeTup) {\n\tif (endNodeTup[1]=='red')\n\t{\n\t\temit(node, endNodeTup);\n\t}\n})\nmakeSound('E4');"
    document.getElementById('purpleCode').value = purpleStartText;
    purple = new Function('node', document.getElementById('purpleCode').value);


}
function moveEmissions() {
    emissions.forEach(function (emission) {
        if (emission[3] >= 100) {
            canvas.remove(emission[0]);
            var index = emissions.indexOf(emission);
            emissions.splice(index, 1);
            pingNode(emission[5]);
        }
        else {
            emission[3] += emission[4];
            var newLocation = getLineXYatPercent(emission[1], emission[2], emission[3])
            emission[0].left = newLocation.x;
            emission[0].top = newLocation.y;
        }
    })
    canvas.renderAll();
}
function addNode(canvas, color) {
    var circle = new fabric.Circle({ radius: 10, fill: color, top: 100, left: 100 })
    circle.hasControls = false;
    nodeTups.push([circle, color]);
    canvas.add(circle);
    console.log(color);
}

function oneSecond() {
    nodeTups.forEach(function (nodeTup) {
        if (nodeTup[1] == 'black'){
            black(nodeTup[0]);
        }
    })

}

function black(node) {
    //nodeTups.forEach(function (endNodeTup) {
    //    emit(node, endNodeTup);
    //})
}

function emit(node, endNodeTup) {
    if (node !== endNodeTup[0]) {
        var start = { x: parseFloat(node.left) + parseFloat(node.radius), y: parseFloat(node.top) + parseFloat(node.radius) };
        var end = { x: parseFloat(endNodeTup[0].left) + parseFloat(endNodeTup[0].radius), y: parseFloat(endNodeTup[0].top) + parseFloat(endNodeTup[0].radius) };
        var d = Math.sqrt(Math.pow((end.x - start.x), 2) + Math.pow((end.y - start.y), 2));
        var perc = 100.0 / d;

        var emission = new fabric.Circle({ radius: 3, fill: 'grey', top: start.y, left: start.x });
        canvas.add(emission);
        emissions.push([emission, start, end, 0, perc, endNodeTup]);
    }  
}

function getLineXYatPercent(startPt, endPt, percent) {
    var dx = endPt.x - startPt.x;
    var dy = endPt.y - startPt.y;
    var X = (startPt.x + dx * percent / 100);
    var Y = (startPt.y + dy * percent/100);
    return ({ x: X, y: Y });
}

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