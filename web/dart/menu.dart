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

/**
 * Menu of blocks that users can build programs out of.
 * Currently sits at the right side of the screen.
 */
class BlockMenu extends Touchable {

  // width of the menu in pixels
  num width;

  // list of blocks in the menu
  List<TuneBlock> blocks = new List<TuneBlock>();

  // menu background color
  String background = "#77838f";

  // link back to workspace
  TunePad workspace;


  BlockMenu(this.width, this.workspace) { 
    workspace.addTouchable(this);
  }

  num colToX(num col) {
    num startX = width * -0.5;
    switch(col) {
      case 0: return startX + width * 0.17;
      case 1: return startX + width * 0.39;
      case 2: return startX + width * 0.61;
      case 3: return startX + width * 0.83;
      default: return 0;
    }
  }


  num rowToY(num row) {
    return 80 * row;
  }


  void initBlocks(var json) {
    num w = width;
    num cx = 0;
    num cy = 85;
    addBlock(new TuneLink(cx, cy));
    cy += 140;
    addBlock(new SplitLink(cx, cy));
    cy += 170;
//    addBlock(new JoinLink(cx, cy));
//    cy += 170;
    addBlock(new PlayLink(cx, cy));
    cy += 170;
    /*
    addBlock(new TunePuck(cx + w * 0.3, cy));
    addBlock(new TunePuck(cx, cy));
    addBlock(new TunePuck(cx - w * 0.3, cy));
    cy += 100;
    addBlock(new TunePuck(cx - w * 0.3, cy));
    addBlock(new TunePuck(cx, cy));
    addBlock(new TunePuck(cx + w * 0.3, cy));
    */
    for (var b in json) {
      switch (b['type']) {
        case 'beat':
          addBlock(new AudioPuck(
            colToX(b['col']), 
            rowToY(b['row']), 
            b['color'],
            b['sound']));
          break;
        case 'tempo-up':
          addBlock(new TempoPuck(colToX(b['col']), rowToY(b['row']), true));
          break;
        case 'tempo-down':
          addBlock(new TempoPuck(colToX(b['col']), rowToY(b['row']), false));
          break;
        case 'volume-up':
          addBlock(new GainPuck(colToX(b['col']), rowToY(b['row']), true));
          break;
        case 'volume-down':
          addBlock(new GainPuck(colToX(b['col']), rowToY(b['row']), false));
          break;
      }
    }
  }


  void addBlock(TuneBlock block) {
    blocks.add(block);
    block.inMenu = true;
  }


  bool animate(int millis) {
    return false;
  }


  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = background;
      ctx.fillRect(menuX, menuY, width, menuH);
      ctx.translate(menuX + width/2, menuY);
      for (int i=0; i<4; i++) {
        for (TuneBlock block in blocks) {
          block.draw(ctx, i);
        }
      }
    }
    ctx.restore();

    ctx.fillStyle = "rgba(0, 0, 0, 0.2)";
    ctx.fillRect(menuX, menuY, width, menuH);

    /*
    if (_target != null && _target.inMenu) {
      for (int i=0; i<4; i++) {
        _target.draw(ctx, i);
      }
    }
    */

    ctx.save();
    {
      ctx.fillStyle = workspace.highlightTrash ? "white" : "rgba(255, 255, 255, 0.5)";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.font = "120px FontAwesome";
      ctx.shadowOffsetX = 5 * workspace.zoom;
      ctx.shadowOffsetY = 5 * workspace.zoom;
      ctx.shadowColor = "rgba(0, 0, 0, 0.5)";
      ctx.shadowBlur = 5 * workspace.zoom;
      ctx.fillText("\uf1f8", menuX + width * 0.5, menuY + menuH - 100);
    }
    ctx.restore();
  }


  bool isOverMenu(num px, num py) {
    return (px >= menuX);
  }


  num get menuX => workspace.worldToObjectX(workspace.width, 0) - width;
  num get menuY => workspace.worldToObjectY(workspace.width, 0);
  num get menuH => workspace.worldToObjectY(workspace.width, workspace.height) - menuY;


  bool containsTouch(Contact event) {
    Contact c = _translateContact(event);
    for (TuneBlock block in blocks) {
      if (block.containsTouch(c)) {
        return true;
      }
    }
    return false;
  }


  Touchable touchDown(Contact event) {
    Contact c = _translateContact(event);
    for (TuneBlock block in blocks) {
      if (block.containsTouch(c)) {
        TuneBlock target = block.clone(
          block.centerX - 6 + menuX + width/2, 
          block.centerY + 6 + menuY);
        target.inMenu = true;
        target.touchDown(event);
        workspace.addBlock(target);
        return target;
      }
    }
    return null;
  }


  void touchUp(Contact event) { }
   
  void touchDrag(Contact event) { }
   
  void touchSlide(Contact event) { }


  Contact _translateContact(Contact event) {
    Contact c = new Contact.copy(event);
    c.touchX -= (menuX + width/2);
    c.touchY -= menuY;
    return c;
  }
}

