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

part "block.dart";
part "puck.dart";
part "pulse.dart";
part "sounds.dart";
part "touch.dart";


// global link to the tunepad workspace
TunePad workspace;


void main() {
  workspace = new TunePad("game-canvas");
  Sounds.loadSound("click", "sounds/click.wav");
  print("Hello");
}




class TunePad extends TouchLayer {

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

    // load some sound effects
    Sounds.loadSound("fire", "sounds/drumkit/rim.wav");

    // create some initial pucks
    addBlock(new TunePuck(300, 300, "sounds/crank.wav"));
    addBlock(new TunePuck(600, 300, "sounds/drumkit/clap.wav") .. background = "#f73");

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


  void addBlock(TuneBlock block) {
    moveToTop(block);  // also adds to the list
    addTouchable(block);
  }


/**
 * Move a block to the top of the visual stack
 */
  void moveToTop(TuneBlock block) {
    if (block is TunePuck) {
      pucks.remove(block);
      pucks.add(block);
    }
  }


/**
 * Fire a pulse with initial position and velocity
 */
  void firePulse(TunePuck parent, num cx, num cy, num vx, num vy) {
    pulses.add(new TunePulse(parent, cx, cy, vx, vy));
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
}


num dist(num x0, num y0, num x1, num y1) {
  return sqrt((x1-x0)*(x1-x0) + (y1-y0)*(y1-y0));
}
