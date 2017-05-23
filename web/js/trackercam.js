var trackerTask;
var tracker;

function onloade(){
  var video = document.getElementById('video');

  this.tracker = new tracking.ColorTracker();

  this.trackerTask = tracking.track('#video', this.tracker, { camera: true });
  trackerStart(this.tracker);

 initGUIControllers(this.tracker);
};

function trackerStart(){
    var canvas = document.getElementById('canvas1');
    var context = canvas.getContext('2d');
    this.tracker.on('track', function(event) {
      context.clearRect(0, 0, canvas.width, canvas.height);
      dartPrint_main('delete');


      event.data.forEach(function(rect) {
        // if (rect.color === 'custom') {
        //   rect.color = this.tracker.customColor;
        // }

        // context.strokeStyle = rect.color;
        // context.strokeRect(rect.x, rect.y, rect.width, rect.height);
        // context.font = '11px Helvetica';
        // context.fillStyle = "#fff";
        // context.fillText('x: ' + rect.x + 'px', rect.x + rect.width + 5, rect.y + 11);
        // context.fillText('y: ' + rect.y + 'px', rect.x + rect.width + 5, rect.y + 22);
        var x = rect.x+(rect.width/2);
        var y = rect.y+(rect.height/2);
        dartPrint_main(String(x)+','+String(y)+','+String(rect.color));
    });
  });
}

function trackerOff(){
  this.trackerTask.stop();
}

function trackerOn(){
  this.trackerTask.run();
}
