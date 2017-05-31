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
  num centerX, centerY;
  num radius = 30;

  // heading of the pulse emitter 
  num heading = 45.0;

  // sound file for this puck
  String sound;

  // icon to draw on the puck
  String icon = "\uf0e7";
  num icon_count = 0;

  String circle_icon = "\uf111";
  String square_icon = "\uf0c8";
  String star_icon = "\uf005";
  String heart_icon = "\uf004";
  //String icon_string = "icon";

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
  num _popR = 0.0;

  // keeps track of if the pulse was recently hit
  bool isHit = false;

  List<TunePuck> to_remove = new List<TunePuck>();


  //list of all pucks that need to be sent to
  //List<TunePuck> pucks = new List<TunePuck>();


  TunePuck(this.centerX, this.centerY, this.sound, this.name) {
    //this.radius = 30;
    Sounds.loadSound(sound, sound);
    Sounds.loadSound("pulse", "sounds/drumkit/rim.wav");
    Sounds.loadSound("cyan_0", "sounds/drumkit/tom.wav");
    Sounds.loadSound("cyan_1", "sounds/drumkit/tick.wav");
    Sounds.loadSound("cyan_2", "sounds/drumkit/tap.wav");
    Sounds.loadSound("magenta_0", "sounds/drumkit/clap.wav");
    Sounds.loadSound("magenta_1", "sounds/drumkit/block.wav");
    Sounds.loadSound("magenta_2", "sounds/drumkit/click.wav");
    Sounds.loadSound("yellow_0", "sounds/drumkit/pat.wav");
    Sounds.loadSound("yellow_1", "sounds/drumkit/hat.wav");
    Sounds.loadSound("yellow_2", "sounds/drumkit/snare.wav");

  	if (this.name == "Black") {
  	    program = new NT.Program(blocks.getStartBlock("while 'play'"), this);
  	    program.batched = false;  // execute blocks one at a time
        program.autoLoop = true;

  	}
  	if (this.name == "Cyan") {
  	    program = new NT.Program(blocks.getStartBlock("when cyan hit"), this);
  	    program.batched = true;  // execute blocks one at a time
        program.autoLoop = false;

  	}
  	if (this.name == "Yellow") {
  	    program = new NT.Program(blocks.getStartBlock("when yellow hit"), this);
  	    program.batched = true;  // execute blocks one at a time
        program.autoLoop = false;

  	}
  	if (this.name == "Magenta") {
  	    program = new NT.Program(blocks.getStartBlock("when magenta hit"), this);
  	    program.batched = true;  // execute blocks one at a time
        program.autoLoop = false;
  	}
  }
  /**
  Function is called when a pulse hits a puck
  **/
  void hit() {
    _pop = 1.0;
    Sounds.playSound(sound, this.radius/50);
    this.isHit = true;
  }

/**
 * This is the ProgramTarget interface (subclasses should redefine).
 * Called by programs during block.eval
 */
  dynamic doAction(String action, List params) {
    if (this.name != "Black"){
      if (this.isHit == false){
        return null;
      }
    }

    switch (action) {
      case "start":
          this.isHit = false;
       		break;

      case "turn":
        num angle = params[0];
        heading = (heading + angle) % 360.0;
        Sounds.playSound("turn");
        break;

      case "rest":
        break;

      case "send to pucks":
        _popR= 1.0;
      	num v = 5;
        bool inRemove = false;

        for (TunePuck puck in workspace.pucks) {
          for (TunePuck puck2 in to_remove) {
            if (puck == puck2){
              inRemove = true;
              break;
            }
          }
          if (!inRemove){
            workspace.sendPulse(this, puck, centerX, centerY, v);
          }
          inRemove = false;
         }
        to_remove = new List<TunePuck>();
        break;


      case "if the puck distance is:":
        String c = params[0];
        num d = params[1];
        num v = 5;
        for (TunePuck puck in workspace.pucks){
          num x_delta = pow((this.centerX - puck.centerX),2);
          num y_delta = pow((this.centerY - puck.centerY),2);
          num true_dist = pow((x_delta+y_delta),0.5);

          if (c== "less than"){
            if (true_dist < d && true_dist > 0){ 
            }
            else {
              to_remove.add(puck);
            }
          }
          else if (c == "greater than") {
            if (true_dist > d && true_dist > 0){
            }
            else {
              to_remove.add(puck);
            }
          }
          else{
            if (true_dist == d && true_dist > 0){
            }
            else {
              to_remove.add(puck);
            }
          }
        }
        return true;
        

      case "if the puck color is:":
        String color = params[0];
        for (TunePuck puck in workspace.pucks){
          if (color != puck.name){
            to_remove.add(puck);
          }
        }
        return true;
      

      case "if the puck shape is:":
        String shape = params[0];
        String icon;

        for (TunePuck puck in workspace.pucks){
          if (puck.icon_count == 0){
            icon = "Bolt";
          }
          if (puck.icon_count == 1){
            icon = "Star";
          }
          if (puck.icon_count == 2){
            icon = "Heart";
          }

          if (shape != icon){
            to_remove.add(puck);
          }
        }
        return true;
       break;
    }

  }



  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = background; 
      ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
      ctx.lineWidth = 5;
      ctx.beginPath();
      int radiusSize = radius + (_popR * 30).toInt();
      ctx.arc(centerX, centerY, radiusSize, 0, PI * 2, true);
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


  bool animate(int millis, CanvasRenderingContext2D ctx) { 
    bool refresh = false;

    if (_pop > 0.05) {
      _pop *= 0.9;
      refresh = true;
    } else {
      _pop = 0.0;
    }

    if (_popR > 0.05) {
      _popR *= 0.9;
      refresh = true;
    } else {
      _popR = 0.0;
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
    //workspace.moveToTop(this);
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;

    if (name == "Cyan"){
      icon_count = (icon_count+1)%3;
      if(icon_count == 0){ //bolt
        icon = "\uf0e7";
        sound = "cyan_0";
      }
      else if (icon_count == 1){  //star
        icon = "\uf005";
        sound = "cyan_1";
      }
      else{  //hart
        icon = "\uf004";
        sound = "cyan_2";
      }
    }

    if (name == "Magenta"){
      icon_count = (icon_count+1)%3;
      if(icon_count == 0){ //bolt
        icon = "\uf0e7";
        sound = "magenta_0";
      }
      else if (icon_count == 1){  //star
        icon = "\uf005";
        sound = "magenta_1";
      }
      else{  //hart
        icon = "\uf004";
        sound = "magenta_2";
      }
    }

    if (name == "Yellow"){
      icon_count = (icon_count+1)%3;
      if(icon_count == 0){ //bolt
        icon = "\uf0e7";
        sound = "yellow_0";
      }
      else if (icon_count == 1){  //star
        icon = "\uf005";
        sound = "yellow_1";
      }
      else{  //hart
        icon = "\uf004";
        sound = "yellow_2";
      }
    }

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

