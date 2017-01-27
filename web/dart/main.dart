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
import 'dart:async';
import 'dart:convert';
import 'dart:web_audio';
import 'dart:typed_data';

//part "beat.dart";
part "block.dart";
part "joint.dart";
part "link.dart";
part "menu.dart";
//part "button.dart";
part "matrix.dart";
part "puck.dart";
//part "sample.dart";
//part "scanner.dart";
part "sounds.dart";
part "touch.dart";


// IMPORTANT! This has to match js/video.js
const VIDEO_WIDTH = 1280; //1920; // 1280; // 800
const VIDEO_HEIGHT = 720; // 1080; // 720; // 600


const PLUG_WIDTH = 40;
const JOINT_WIDTH = 35;
const SOCKET_WIDTH = 70;
const PUCK_WIDTH = 60;



// 1000 ms == quarter note
// 500 ms == 8th note
const millisPerBeat = 250;      // 250 ms == 16th note
const beatsPerMeasure = 16;     // 16th notes as our smallest division (4 / 4 time)
const millisPerMeasure = 4000;  // measures are 4,000 ms long

Stopwatch clock = new Stopwatch(); // used to synchronize animation and vocalization timing

AudioContext audio = new AudioContext();


TunePad workspace;


void main() {
  workspace = new TunePad("video-canvas");
  workspace.loadBlocks("json/blocks.json");
}


class TunePad extends TouchLayer {

  // size of the canvas
  int width, height;

  // global scale of the canvas
  num zoom = 1.0;

  // Canvas 2D drawing context
  CanvasRenderingContext2D ctx;

  // Touch event manager
  TouchManager tmanager = new TouchManager();

  // List of all blocks on the screen
  List<TuneLink> links = new List<TuneLink>();
  List<TunePuck> pucks = new List<TunePuck>();


  // block menu
  BlockMenu menu;


  TunePad(String canvasId) {
    CanvasElement canvas = querySelector("#$canvasId");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;
    menu = new BlockMenu(250, this);

    // register touch events
    tmanager.registerEvents(canvas);
    tmanager.addTouchLayer(this);

    clock.start();

    // start animation timer
    window.animationFrame.then(animate);

    zoomIn(0.5);
    // start audio timer
    //new Timer.periodic(const Duration(milliseconds : millisPerBeat), (timer) => vocalize());
    new Timer(const Duration(milliseconds : 100), () => draw());
  }


/**
 * Main audio loop. Set on a periodic timer at 250ms (16th note metronome)
 */
  int _millis = 0; 
/*  
  void vocalize() {
    int millis = clock.elapsedMilliseconds;
    for (TuneBlock block in blocks) {
      if (block is StartBlock) {
        block.stepProgram(millis);
      }
      else if (block is BeatBlock) {
        block.eval(millis);
      }
    }
  }
*/


/** 
 * Match a puck to socket
 */
  Socket findMatchingSocket(TunePuck puck) {
    for (TuneLink link in links) {
      for (Joint j in link.joints) {
        if (j is Socket) {
          num dx = j.cx - puck.centerX;
          num dy = j.cy - puck.centerY;
          if (sqrt(dx * dx + dy * dy) <= (j.radius + puck.radius)) {
            return j;
          }
        }
      }
    }
    return null;
  }


/**
 * Main animation / draw loop. This is separate from audio loop and runs on the window.animationFrame
 * timer.
 */
  void animate(num t) {
    int millis = clock.elapsedMilliseconds;
    bool refresh = false;
    for (TuneLink link in links) {
      if (link.animate(millis)) refresh = true;
    }
    if (_pdragging) refresh = true;
    _pdragging = false;
    for (TunePuck puck in pucks) {
      if (puck.animate(millis)) refresh = true;
      if (puck.isDragging) _pdragging = true;
    }
    if (menu.animate(millis)) refresh = true;
    if (refresh) draw();
    window.animationFrame.then(animate);
  }


  void drawLayer(int layer) {
    for (TuneLink link in links) {
      if (!link.inMenu) link.draw(ctx, layer);
    }
    for (TunePuck puck in pucks) {
      if (!puck.inMenu) puck.draw(ctx, layer);
    }
  }


  void draw() {
    ctx.fillStyle = "#abc";
    ctx.fillRect(0, 0, width, height);
    ctx.strokeStyle = "black";
    ctx.strokeRect(0, 0, width, height);
    ctx.save();
    {
      //setScale(scale, scale);
      transformContext(ctx);
      //ctx.scale(scale,scale);
      for (int i=0; i<4; i++) {
        drawLayer(i);
      }
      menu.draw(ctx);
    }
    ctx.restore();
      
/*

    Uint8List adata = Sounds.analyzeSound();

    if (adata != null) {

      ctx.save();
      {
        ctx.lineWidth = 2;
        ctx.beginPath();
        num sliceWidth = 500.0 / adata.length;
        num x = 0.0;
        for (int i=0; i<adata.length; i++) {
          num v = adata[i] / 128.0;
          num y = v * 130.0 + 300.0;
          if (i == 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
          x += sliceWidth;
        }
        ctx.lineTo(500, 430);
        ctx.stroke();
      }
      ctx.restore();
    }
*/    
  }


  void addBlock(TuneBlock block) {
    moveToTop(block);
    addTouchable(block);
  }


/**
 * Move a block to the top of the visual stack
 */
  void moveToTop(TuneBlock block) {
    if (block is TuneLink) {
      links.remove(block);
      links.add(block);
    } else if (block is TunePuck) {
      pucks.remove(block);
      pucks.add(block);
    }
  }


/**
 * This flag is used by sockets to do flash highlighting
 */
  bool get isPuckDragging => _pdragging;
  bool _pdragging = false;


/** 
 * Zooms the entire screen in or out
 */  
  void zoomIn(num factor) {
    zoom *= factor;
    scaleAroundPoint(
      factor, factor, 
      worldToObjectX(width/2, height/2), 
      worldToObjectY(width/2, height/2));
  }


  bool keyDown(KeyboardEvent kbd) {
    num delta = 5 / zoom;
    num cx = worldToObjectX(width/2, height/2);
    num cy = worldToObjectY(width/2, height/2);
    switch (kbd.keyCode) {
      case 189: 
        zoomIn(0.98);
        break;
      case 187: 
        zoomIn(1 / 0.98);
        break;
      case 37: 
        translate(delta, 0); 
        break;
      case 38: 
        translate(0, delta); 
        break;
      case 39: 
        translate(-delta, 0); 
        break;
      case 40: 
        translate(0, -delta); 
        break;
      case 48: 
        resetTransform(); 
        break;
      default: 
        print(kbd.keyCode); 
        break;
    }
    draw();
  }


/**
 * Load blocks from a JSON definition file
 */
  void loadBlocks(String url) {
    var request = HttpRequest.getString(url).then((responseText) {
      var json = JSON.decode(responseText);
      menu.initBlocks(json);
    });
  }

}

