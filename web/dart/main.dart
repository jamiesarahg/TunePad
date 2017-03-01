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
part "play.dart";
part "puck.dart";
part "score.dart";
part "socket.dart";
part "sounds.dart";
part "split.dart";
part "touch.dart";


const PLUG_WIDTH = 40;
const JOINT_WIDTH = 35;
const SOCKET_WIDTH = 70;
const PUCK_WIDTH = 60;



const millisPerBeat = 128;      // 128ms == 32nd note
const beatsPerMeasure = 32;     // 32nd notes as our smallest division (4 / 4 time)
const millisPerMeasure = 4096;  // measures are 4096 ms long

Stopwatch clock = new Stopwatch(); // used to synchronize animation and vocalization timing

AudioContext audio = new AudioContext();


TunePad workspace;

TuneScore score;


void main() {
  workspace = new TunePad("video-canvas");
  workspace.loadBlocks("json/blocks.json");
  Sounds.loadSound("click", "sounds/click.wav");
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
  bool _playing = false;

  // shows hint message
  String _hintText = null;
  double _hintAlpha = 0.0;


  TunePad(String canvasId) {
    CanvasElement canvas = querySelector("#$canvasId");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;
    menu = new BlockMenu(350, this);
    // score shows notes over time
    score = new TuneScore(0, height, width - 350);


    // register touch events
    tmanager.registerEvents(canvas);
    tmanager.addTouchLayer(this);

    // master clock for audio timing
    clock.start();

    // start animation timer
    window.animationFrame.then(animate);

    // restart button
    bindClickEvent("restart-button", (e) {
      window.location.reload();
    });

    zoomIn(0.85);

    // start audio timer
    new Timer.periodic(const Duration(milliseconds : 25), (timer) => vocalize());

    // let things load and then repaint
    new Timer(const Duration(milliseconds : 500), () => draw());
    new Timer(const Duration(milliseconds : 3000), () => draw());
  }


/**
 * This flag is used by sockets to do flash highlighting
 */
  bool get isPuckDragging => _puckdrag;
  bool get highlightTrash => _highlightTrash;
  bool get isPlaying => _playing;


/**
 * Main audio loop. Set on a periodic timer at 125ms (32nd note metronome)
 */
  void vocalize() {
    int millis = clock.elapsedMilliseconds;

    if (millis >= _lastbeat + millisPerBeat) {
      _playing = false;
      _lastbeat = (millis ~/ millisPerBeat) * millisPerBeat;

      for (TuneLink link in links) {
        if (link is PlayLink) {
          (link as PlayLink).stepProgram(_lastbeat);
          if ((link as PlayLink).isPlaying) _playing = true;
        }
      }
    }
  }


  void showHint(String hint) {
    _hintText = hint;
    _hintAlpha = 0.5;
  }


  void clearHint() {
    _hintText = null;
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
          if (s.canAcceptPuck(puck)) {
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
 * Main animation / draw loop. This is separate from audio loop and runs 
 * on the window.animationFrame timer.
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

    // animate the score
    score.animate(t);
    if (isPlaying) score.draw(ctx);

    // trigger next animation frame
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

    // hint message
    if (_hintText != null && _hintAlpha > 0.0) {
      ctx.fillStyle = "rgba(0, 0, 0, ${_hintAlpha})";
      ctx.textAlign = "left";
      ctx.font = "600 30px sans-serif";
      ctx.fillText("$_hintText", 130, 80);
    }

    ctx.save();
    {
      //setScale(scale, scale);
      transformContext(ctx);
      //ctx.scale(scale,scale);
      menu.draw(ctx);

      for (int i=0; i<5; i++) {
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


/**
 * Binds a click event to a button
 */
void bindClickEvent(String id, Function callback) {
  Element element = querySelector("#${id}");
  if (element != null) {
    if (isFlagSet("debug")) {
      element.onClick.listen(callback);
    } else {
      element.onTouchStart.listen(callback);    
    }
  }
}


/**
 * Distance between two points
 */
num dist(num x0, num y0, num x1, num y1) {
  return sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
}
