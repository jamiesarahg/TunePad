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

part "block.dart";
part "joint.dart";
part "link.dart";
part "menu.dart";
part "matrix.dart";
part "playhead.dart";
part "puck.dart";
part "socket.dart";
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
const millisPerBeat = 125;      // 250 ms == 32nd note
const beatsPerMeasure = 32;     // 32nd notes as our smallest division (4 / 4 time)
const millisPerMeasure = 4000;  // measures are 4,000 ms long

Stopwatch clock = new Stopwatch(); // used to synchronize animation and vocalization timing

AudioContext audio = new AudioContext();


TunePad workspace;


void main() {
  workspace = new TunePad("video-canvas");
  workspace.loadBlocks("json/blocks.json");
  Sounds.loadSound("click", "sounds/drumkit/click.wav");
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

  int _lastbeat = 0;

  bool _puckdrag = false;
  bool _highlightTrash = false;



  TunePad(String canvasId) {
    CanvasElement canvas = querySelector("#$canvasId");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;
    menu = new BlockMenu(350, this);

    // register touch events
    tmanager.registerEvents(canvas);
    tmanager.addTouchLayer(this);

    clock.start();

    // start animation timer
    window.animationFrame.then(animate);

    zoomIn(0.75);
    // start audio timer
    new Timer.periodic(const Duration(milliseconds : 25), (timer) => vocalize());
    new Timer(const Duration(milliseconds : 100), () => draw());
  }


/**
 * This flag is used by sockets to do flash highlighting
 */
  bool get isPuckDragging => _puckdrag;
  bool get highlightTrash => _highlightTrash;


/**
 * Main audio loop. Set on a periodic timer at 125ms (32nd note metronome)
 */
  void vocalize() {
    int millis = clock.elapsedMilliseconds;

    if (millis >= _lastbeat + millisPerBeat) {
      _lastbeat = (millis ~/ millisPerBeat) * millisPerBeat;

      for (TuneLink link in links) {
        if (link is PlayLink) {
          (link as PlayLink).stepProgram(_lastbeat);
        }
      }
    }
  }


  bool isOverMenu(num px, num py) {
    return menu.isOverMenu(px, py);
  }


/** 
 * Match a puck to a socket
 */
  Socket findMatchingSocket(TunePuck puck) {
    for (TuneLink link in links) {
      for (Joint j in link.joints) {
        if (j is Socket) {
          Socket s = j as Socket;
          if (s.puck == null && s.canAcceptPuck(puck)) {
            num dx = j.cx - puck.centerX;
            num dy = j.cy - puck.centerY;
            if (sqrt(dx * dx + dy * dy) <= (j.radius + puck.radius)) {
              return j;
            }
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

    if (_highlightTrash) refresh = true;
    _highlightTrash = false;
    // animate and then relax to relieve spring forces
    for (TuneLink link in links) {
      if (link.animate(millis)) refresh = true;
      if (link.isDragging && link.isOverMenu && !link.inMenu) _highlightTrash = true;
    }
    for (TuneLink link in links) {
      link.relax();
    }
    if (_puckdrag) refresh = true;
    _puckdrag = false;
    for (TunePuck puck in pucks) {
      if (puck.animate(millis)) refresh = true;
      if (puck.isDragging) _puckdrag = true;
      if (puck.isDragging && puck.isOverMenu && !puck.inMenu) _highlightTrash = true;
    }
    if (menu.animate(millis)) refresh = true;
    if (refresh) draw();
    window.animationFrame.then(animate);
  }


  void drawLayer(int layer) {
    for (TuneLink link in links) {
      link.draw(ctx, layer);
    }
    for (TunePuck puck in pucks) {
      puck.draw(ctx, layer);
    }
  }


  void draw() {
    removeTrash();

    ctx.fillStyle = "#abc";
    ctx.fillRect(0, 0, width, height);
    ctx.strokeStyle = "black";
    ctx.strokeRect(0, 0, width, height);
    ctx.save();
    {
      //setScale(scale, scale);
      transformContext(ctx);
      //ctx.scale(scale,scale);
      menu.draw(ctx);

      for (int i=0; i<4; i++) {
        drawLayer(i);
      }
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


  void removeTrash() {
    for (int i=links.length - 1; i >= 0; i--) {
      TuneLink link = links[i];
      if (link.trash) {
        links.removeAt(i);
        removeTouchable(link);
      }
    }
    for (int i=pucks.length - 1; i >= 0; i--) {
      TunePuck puck = pucks[i];
      if (puck.trash) {
        pucks.removeAt(i);
        removeTouchable(puck);
      }
    }
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

