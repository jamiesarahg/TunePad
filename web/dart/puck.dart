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
part of TunePad;


class TunePuck implements Touchable, NT.ProgramTarget {

  // size and position of the block
  num centerX, centerY, radius;

  // heading of the pulse emitter 
  num heading = 45.0;

  // sound file for this puck
  String sound;

  // icon to draw on the puck
  String icon = "\uf0e7";

  // font face
  String font = "FontAwesome";

  // foreground color of the block
  String color = "rgba(255, 255, 255, 0.9)";

  // background color of the block
  String background = "rgb(0, 160, 227)";

  // background color name of block
  String name = "Blue";

  // used to randomize some commands
  Random rnd = new Random();

  // every block runs its own NetTango program
  NT.Program program;

  // variables for touch interaction
  bool _dragging = false;
  num _touchX, _touchY, _lastX, _lastY;

  // animates sounds playing
  num _pop = 0.0;




  TunePuck(this.centerX, this.centerY, this.sound) {
    this.radius = 30;
    Sounds.loadSound(sound, sound);
    Sounds.loadSound("turn", "sounds/drumkit/block.wav");
    Sounds.loadSound("pulse", "sounds/drumkit/rim.wav");
    program = new NT.Program(blocks.start, this);
    program.batched = false;  // execute blocks one at a time
  }


  void hit() {
    _pop = 1.0;
    Sounds.playSound(sound);
  }



/**
 * This is the ProgramTarget interface (subclasses should redefine).
 * Called by programs during block.eval
 */
  dynamic doAction(String action, List params) {
  	print(action);
  	if (workspace.cameraOn == true) {
  		(js.context['trackerOff'] as js.JsFunction).apply([]);
  		workspace.cameraOn = false;
  	}
    switch (action) {
      case "start":
       		break;
      case "turn":
        num angle = params[0];
        heading = (heading + angle) % 360.0;
        Sounds.playSound("turn");
        break;

      case "pulse":
      	if (workspace.cameraOn == false) {
	        print('pulse');
	        num velocity = params[0];
	        num dx = velocity * cos(PI * heading / 180.0);
	        num dy = velocity * sin(PI * heading / 180.0);
	        workspace.firePulse(this, centerX, centerY, dx, dy);
	        Sounds.playSound("pulse");
	     }
        break;

      case "rest":
        break;

      case "send to":
      	num v = 5;
      	String color = params[0];
      	for (TunePuck puck in workspace.pucks) {
      		if (puck.name == color){
      			workspace.sendPulse(this, puck, centerX, centerY, v);
      		}
      	}
      	break;

      default:
    }
    return null;
  }



  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = background; 
      ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
      ctx.lineWidth = 5;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, PI * 2, true);
      ctx.stroke();
      ctx.fill();
      _drawIcon(ctx);
    }
    ctx.restore();
  }


  void _drawIcon(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.fillStyle = color; 
      int size = 32 + (_pop * 60).toInt();
      ctx.font = "${size}px $font";
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
      ctx.fillText("$icon", 0, 0);
    }
    ctx.restore();
  }


  bool animate(int millis) { 
    bool refresh = false;
    if (_dragging) {
      centerX += (_touchX - _lastX);
      centerY += (_touchY - _lastY);
      _lastX = _touchX;
      _lastY = _touchY;
      refresh = true;
    } 
    if (_pop > 0.05) {
      _pop *= 0.9;
      refresh = true;
    } else {
      _pop = 0.0;
    }
    return refresh;
  }


/**
 * This is the Touchable interface
 */
  bool containsTouch(Contact c) {
    return dist(c.touchX, c.touchY, centerX, centerY) <= radius;
  }


  Touchable touchDown(Contact c) {
    _dragging = true;
    workspace.moveToTop(this);
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;

    workspace.firePulse(this, centerX, centerY, 7, -7);

    return this;
  }    


  void touchUp(Contact c) {
    _dragging = false;
    workspace.draw();
  }


  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;    
  }
   
  void touchSlide(Contact c) {  
  }
}

/*
  void eval(PlayHead player) {
    Sounds.playSound(sound, 
      volume : player.gain, 
      playback : player.playback,
      convolve : player.convolve);
    _pop = 1.0;
  }
*/

