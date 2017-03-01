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
          addBlock(new AudioPuck(colToX(b['col']), rowToY(b['row']), b['color'], b['sound']));
          break;
        case 'sound':
          addBlock(new AudioPuck(colToX(b['col']), rowToY(b['row']), b['color'], b['sound']) .. icon = "\uf001");
          break;
        case 'tempo':
          addBlock(new TempoPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'volume':
          addBlock(new GainPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'pitch':
          addBlock(new PitchPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'distort':
          addBlock(new DistortPuck(colToX(b['col']), rowToY(b['row']), b['impulse'], b['hint']));
          break;
        case 'reset':
          addBlock(new ResetPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'random':
          addBlock(new RandomPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'split':
          addBlock(new SplitPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'loop':
          addBlock(new LoopPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
          break;
        case 'jump':
          addBlock(new JumpPuck(colToX(b['col']), rowToY(b['row']), b['hint']));
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

    // draw trashcan !
    ctx.save();
    {
      ctx.fillStyle = workspace.highlightTrash ? "white" : "rgba(0, 0, 0, 0.4)";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.font = "86px FontAwesome";
      ctx.shadowOffsetX = -1 * workspace.zoom;
      ctx.shadowOffsetY = -1 * workspace.zoom;
      ctx.shadowColor = "rgba(255, 255, 255, 0.5)";
      ctx.shadowBlur = 1 * workspace.zoom;
      ctx.fillText("\uf1f8", menuX + width * 0.5, menuY + menuH - 70);
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



/**
 * Pie menu for pucks
 */
class PieMenu {

  List<PuckMenuItem> _items = new List<PuckMenuItem>();

  TunePuck parent;


  PieMenu(this.parent);


  PuckMenuItem operator[](int index) => _items[index];

  bool get isEmpty => _items.isEmpty;

  int get segments => _items.length;

  num get arc => PI / max(1, segments);

  num get r1 => parent.radius * 1.15;

  num get r2 => parent.radius * 4;

  num get centerX => parent.centerX;

  num get centerY => parent.centerY;


  void addItem(String icon, var data, [bool selected = false]) {
    _items.add(new PuckMenuItem(icon, data) .. selected = selected);
  }


  void setFont(String font) {
    for (PuckMenuItem item in _items) {
      item.font = font;
    }
  }


  void draw(CanvasRenderingContext2D ctx, num touchX, num touchY) {
    if (isEmpty) return;
    ctx.save();
    {
      ctx.translate(centerX, centerY);

      // figure out the highlighted menu slice
      int target = _screenToMenuIndex(touchX, touchY);

      // menu segments
      for (int i=0; i<segments; i++) {
        if (i == target) {
          _fillWedge(ctx, i, "white");
          _fillText(ctx, i, "#777");
        }
        else if (_items[i].selected) {
          _fillWedge(ctx, i, "#444");
          _fillText(ctx, i, "#eee");
        } else {
          _fillWedge(ctx, i, "#ddd");
          _fillText(ctx, i, "#777");
        }

        ctx.save();
        {
          ctx.strokeStyle = "#777";
          ctx.rotate(PI * 0.5 - arc * i);
          ctx.beginPath();
          ctx.moveTo(0, -r1);
          ctx.lineTo(0, -r2);
          ctx.stroke();
        }
        ctx.restore();
      }

      ctx.strokeStyle = "#777";
      ctx.beginPath();
      ctx.moveTo(r2, 0);
      ctx.arc(0, 0, r2, 0, PI, true);
      ctx.lineTo(-r1, 0);
      ctx.stroke();
    }
    ctx.restore();
  }


  void _fillWedge(CanvasRenderingContext2D ctx, int index, String bg) {
    ctx.save();
    {
      ctx.rotate(PI * 0.5 - arc * index);
      ctx.fillStyle = bg;
      ctx.beginPath();
      ctx.moveTo(0, -r1);
      ctx.lineTo(0, -r2);
      ctx.arc(0, 0, r2, -PI/2, -PI/2 - arc, true);
      ctx.arc(0, 0, r1, -PI/2 - arc, -PI/2, false);
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();
  }


  void _fillText(CanvasRenderingContext2D ctx, int index, String fg) {
    ctx.save();
    {
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
      ctx.fillStyle = fg;
      ctx.font = _items[index].font;
      num theta = -arc * index - arc * 0.5;
      num dx = r1 * 2.3 * cos(theta);
      num dy = r1 * 2.3 * sin(theta);
      ctx.fillText("${_items[index].icon}", dx, dy);
    }
    ctx.restore();
  }


  void touchUp(num tx, num ty) {
    int index = _screenToMenuIndex(tx, ty);
    if (index >= 0 && index < segments) {
      for (PuckMenuItem m in _items) {
        m.selected = false;
      }
      parent.icon = _items[index].icon;
      _items[index].selected = true;
      parent.menuSelection(_items[index]);
    }
  }


  int _screenToMenuIndex(num tx, num ty) {
    tx -= parent.centerX;
    ty -= parent.centerY;
    num alpha = atan2(-ty, tx);
    if (alpha < 0) alpha += 2 * PI;
    int target = alpha ~/= arc;
    num d = dist(tx, ty, 0, 0);
    if (d >= r1 && d <= r2) {
      return target;
    } else {
      return -1;
    }
  }  
}


/**
 * Each item in the menu knows how to draw itself
 */
class PuckMenuItem {

  String icon = "";
  var data;
  String font = "34px tune-pad";
  bool selected = false;

  PuckMenuItem(this.icon, this.data);
}


