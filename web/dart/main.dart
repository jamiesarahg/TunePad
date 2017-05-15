/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2017, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
library TunePad;

import 'dart:html';
import 'dart:math';
import 'dart:async';      // timers 
import 'dart:convert';    // JSON library
import 'dart:web_audio';  // web audio
import 'package:NetTango/ntango.dart' as NT;   // import NetTango

part "blocks.dart";
part "puck.dart";
part "pulse.dart";
part "sounds.dart";
part "touch.dart";


const millisPerBeat = 256; // 128;      // 128ms == 32nd note
const beatsPerMeasure = 32;     // 32nd notes as our smallest division (4 / 4 time)
const millisPerMeasure = 4096;  // measures are 4096 ms long

Stopwatch clock = new Stopwatch(); // used as metronome

// global link to the tunepad workspace
TunePad workspace;

// global link to the block workspace
NT.CodeWorkspace blocks;



void main() {
  blocks = new NT.CodeWorkspace(BLOCKS);
  workspace = new TunePad("game-canvas");
  blocks.runtime = workspace;
  Sounds.loadSound("click", "sounds/click.wav");
}




class TunePad extends TouchLayer with NT.Runtime {

  // size of the canvas
  int width, height;

  // Canvas 2D drawing context
  CanvasRenderingContext2D ctx;

  // Touch event manager
  TouchManager tmanager = new TouchManager();

  // list of all sound generator pucks on the canvas
  List<TunePuck> pucks = new List<TunePuck>();

  // list of pulses fired
  List<TunePulse> pulses = new List<TunePulse>();



  TunePad(String canvasId) {
    CanvasElement canvas = querySelector("#$canvasId");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;

    // register touch events
    tmanager.registerEvents(canvas);
    tmanager.addTouchLayer(this);

    //get pucks in puck.dart

    // master clock for audio timing
    clock.start();

    // start program step timer
    new Timer.periodic(const Duration(milliseconds : 25), (timer) => vocalize());    

    // create some initial pucks
    addBlock(new TunePuck(300, 300, "sounds/crank.wav"));
    addBlock(new TunePuck(600, 300, "sounds/drumkit/clap.wav") .. background = "#f73");
    addBlock(new TunePuck(400, 100, "sounds/drumkit/tom.wav") .. background = "#7733ff");

    // start animation timer
    window.animationFrame.then(animate);

    // initial repaint
    new Timer(const Duration(milliseconds : 500), () => draw());    
  }


/**
 * Main animation / draw loop. 
 */
  void animate(num t) {

    bool refresh = false;      

    // animate the audio pucks
    for (TunePuck puck in pucks) {
      if (puck.animate(t)) refresh = true;
    }


    // animate pulses and remove dead pulses 
    // (make sure move backwards through the list)
    for (int i=pulses.length - 1; i >= 0; i--) {
      TunePulse pulse = pulses[i];
      if (pulse.animate(t)) refresh = true;
      if (pulse.dead) pulses.removeAt(i);
    }

    // only draw if we need to 
    if (refresh) draw();

    // trigger next animation frame
    window.animationFrame.then(animate);
  }


/**
 * Advance program at 32nd note intervals
 */
  int _lastbeat = 0; 
  void vocalize() {
    int millis = clock.elapsedMilliseconds;

    if (millis >= _lastbeat + millisPerBeat) {

      _lastbeat = (millis ~/ millisPerBeat) * millisPerBeat;
      if (isRunning) {
        for (TunePuck puck in pucks) {
          puck.program.step();
        }
      }
    }
  }  


/**
 * Repaint the screen
 */
  void draw() {
    // clear the screen
    ctx.fillStyle = "#abc";
    ctx.fillRect(0, 0, width, height);

    ctx.save();
    {

      pulses.forEach((pulse) => pulse.draw(ctx));

      pucks.forEach((puck) => puck.draw(ctx));

    }
    ctx.restore();
  }


  void addBlock(TunePuck puck) {
    moveToTop(puck);  // also adds to the list
    addTouchable(puck);
  }


/**
 * Move a block to the top of the visual stack
 */
  void moveToTop(TunePuck puck) {
    pucks.remove(puck);
    pucks.add(puck);
  }


/**
 * Fire a pulse with initial position and velocity
 */
  void firePulse(TunePuck parent, num cx, num cy, num vx, num vy) {
    num x = 1;
    for (TunePuck puck in pucks) {
      pulses.add(new TunePulse(parent, cx, cy , 7, 0));
      x = x*10;
    }
}


/**
 * check to see if the given pulse has collided with any pucks
 */
  TunePuck collisionCheck(TunePulse pulse) {
    for (TunePuck puck in pucks) {
      if (puck != pulse.parent) {
        num d = dist(puck.centerX, puck.centerY, pulse.cx, pulse.cy);
        if (d <= puck.radius + pulse.radius) {
          return puck;
        }
      }
    }
    return null;
  }


/**
 * Runtime interface
 */
  void setup() {
    // called when the restart button is pressed    
  }

  void programChanged() {
    // called whenever the program is changed
  }

  void stepForward() {
    // Step forward 1 tick (step forward button pressed)
  }
}


num dist(num x0, num y0, num x1, num y1) {
  return sqrt((x1-x0)*(x1-x0) + (y1-y0)*(y1-y0));
}
